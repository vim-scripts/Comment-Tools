#!/usr/bin/env ruby
# comment-tools.rb -- Methods for manipulating comments from within Vim.
# File: "/home/johannes/prj/vim/comment-tools/comment-tools.rb"
# 
# Created: Thu, 22 May 2003 11:45:16 +0200
# Last Modification: "Tue, 17 Jun 2003 10:00:54 +0200 (johannes)"
 
=begin
  Copyright (C) 2003  Johannes Tanzler <johannes.tanzler@aon.at>

  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
=end

=begin Provides:
  VIM::Buffer#append_comment(line_number, column=40)
  VIM::Buffer#format_comments(from_line, to_line)
=end

require 'vim/vim-ruby'

module VIM

  class Buffer

    def append_comment(line_number, column=40)
      characters = comment_characters
      if characters.nil?
        puts "CommentTools: Don't know comment characters for this file type."
        puts "Set b:CommentTools_Characters."
        return
      else
        commentify(line_number, characters, column)
      end
    end

    def format_comments(first, last)

      first = first.to_i
      last  = last.to_i

      s, e = comment_characters
      if s.nil? and e.nil?
        puts "CommentTools: Don't know comment characters for this file type."
        puts "Set b:CommentTools_Characters."
        return
      end

      comment_column = 0
      skip = []
      first.upto(last) do |line_number|
        line = $curbuf[line_number]

        line_comment = has_comment(line_number, s)
        if line_comment 
          if line_comment > comment_column
            comment_column = line_comment
          end
        else
          skip.push line_number
        end
      end

      return if comment_column == 0   # no comments found
      first.upto(last) do |line_number|
        unless skip.include?(line_number)
          commentify(line_number, [s, e], comment_column+1)
        end
      end

    end

    def kill_comment(line_number)
      s, e = comment_characters
      if s.nil? and e.nil?
        puts "CommentTools: Don't know comment characters for this file type."
        puts "Set b:CommentTools_Characters."
        return
      end

      comment_column = 0

      line = $curbuf[line_number]
      line_comment = has_comment(line_number, s)
      if e.nil?
        # it's trivial if comment goes from s to end of line:
        $curbuf[line_number] = line[0,line_comment]
      else
        # this is more difficult:
        loop do
          soc = has_comment(line_number, s)  # start of comment
          break if soc.nil?
          soc += 1

          # get position of end of comment:
          eoc = (line[soc..-1] =~ e.gsub(/\//, '\/').gsub(/\*/, '\\*'))
          return if eoc.nil?           # this may no happen, so return

          eoc += (e.length+1)

          line = $curbuf[line_number]
          line[soc-1, eoc] = ""
          line.gsub!(/\s*$/, '')
          $curbuf[line_number] = line
        end
      end
    end

    private

    def commentify(line_number, characters, column)
      line = $curbuf[line_number]

      s, e = characters
      if line =~ s.gsub(/\//, '\/').gsub(/\*/, '\\*')

        # Align comment if there really is one.

        comment_at = has_comment(line_number, s)
        if comment_at
          align_comment(line_number, s, comment_at, column)
        end

      else

        # There was no comment, so insert a new one:

        insert_comment(line_number, column, s, e)

        # Start insert:
        if e.nil?
          VIM::normal("$")
        else
          VIM::normal("$")
          VIM::normal("#{e.length}h")
        end
        VIM::command("startinsert")

      end 
    end

    # Insert a comment in line 'line_number' at column 'column', where a
    # comment starts with 's' and ends with 'e'
    def insert_comment(line_number, column, s, e=nil)
      line = $curbuf[line_number]
      tmp = s + " "
      tmp += " #{e}" if e

      line.gsub!(/\s*$/, '')
      if line =~ /^\s*$/             # special treatment for empty lines:
        $curbuf[line_number] = tmp
        VIM::normal("=l")
        #elsif line.length >= column.to_i or line =~ /(#endif|})$/
      elsif line.length >= column.to_i or line =~ /(#{endwords.split(",").join("|")})$/
        $curbuf[line_number] = line + "  " + tmp
      else
        rjust_val = column.to_i - line.length + s.length
        rjust_val += (e.length + 1) if e
        tmp = tmp.rjust(rjust_val)
        $curbuf[line_number] = line + tmp
      end
    end

    # If line has a comment (synID tells us), return column where comment
    # starts. Otherwise, return nil.
    # At column 'start_at', start to check.
    def has_comment(line_number, s)
      line = $curbuf[line_number]

      comment_at = nil
      0.upto(line.length-1) do |i|
        c = line[i,s.length]
        if c == s
          synID = VIM::evaluate("synIDattr(synIDtrans(synID(#{line_number}, #{i+1}, 1)), \"name\")")
          if synID == "Comment"
            comment_at = i
            break
          end
        end
      end
      comment_at
    end

    # Align the comment in 'line_number' that starts with 's' and currently is
    # at 'comment_at' to 'column'
    def align_comment(line_number, s, comment_at, column)
      return if comment_at.nil?
      line = $curbuf[line_number]
      if line[0, comment_at] =~ /^\s*$/
        # At start of line, align to current indentation using Vim's
        # built-in indentation 
        VIM::normal("=l")
      else
        # Otherwise, align it to 'column'
        first_part = line[0..(comment_at-s.length)]
        rest = line[comment_at..-1]
        first_part.gsub!(/\s*$/, '')

        
        if first_part.length >= column.to_i or first_part =~ /(#{endwords.split(",").join("|")})$/
          $curbuf[line_number] = first_part + "  " + rest
        else
          tmp = first_part
          (column.to_i - first_part.length - 1).times { tmp += " " }
          tmp += rest
          $curbuf[line_number] = tmp
        end
      end
    end

    # Return comment characters for current filetype
    # Use b:CommentTools_Characters if set.
    def comment_characters

      chars = VIM::variable("b:CommentTools_Characters")
      
      if chars.nil?
        ft = $curbuf.filetype
        chars = 
        case ft
        when 'c', 'css' 
          "/*,*/"
        when 'html', 'xml', 'xhtml'
          "<!--,-->"
        when 'ox', 'cpp', 'php', 'java' then "//"
        when 'ruby', 'perl', 'python', 'sh', 'tcl' then "#"
        when 'lisp', 'scheme' then ";"
        when 'tex' then "%"
        when 'caos' then "*"
        when 'vim' then "\""
        end
      end

      chars.split(",") unless chars.nil?
    end

    # Return a comma-separated list of endwords (where only 2 spaces are
    # inserted before the comment)
    def endwords
      endwords = VIM::variable("b:CommentTools_Endwords")
      if endwords.nil?
        endwords = "#endif,}"
      end
      endwords
    end

  end

end

