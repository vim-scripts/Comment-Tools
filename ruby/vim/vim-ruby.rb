#!/usr/bin/env ruby
# FILE: "/home/johannes/prj/vim/ruby/vim-ruby.rb"
# CREATED: Mon, 26 Aug 2002 20:05:58 +0200
# LAST MODIFICATION: "Sat, 07 Jun 2003 11:29:28 +0200 (johannes)"
# (C) 2002 by Johannes Tanzler, <jtanzler@yline.com>

module VIM

=begin
--- VIM::normal(aCommand)
    Execute normal mode command ((|aCommand|))
=end
  def self.normal(cmd)
    VIM::command("normal #{cmd}")
  end

  def self.variable(var_name)
    ret = nil
    if VIM::evaluate("exists(\"#{var_name}\")") != "0"
      ret = VIM::evaluate("#{var_name}")
    end
    ret
  end

=begin
--- VIM::Window::columns
    Returns the number of the current window's columns.
=end
  class Window
    def columns
      VIM::evaluate('&columns').to_i
    end
    def row
      $curwin.cursor[0]
    end
    alias_method :line, :row
    def col
      $curwin.cursor[1]
    end
  end

=begin
--- VIM::Buffer::row
    Returns the cursor's row (line).
--- VIM::Buffer::col
    Returns the cursor's column.
--- VIM::Buffer::append2(string, row=$curbuf.row)
    Appends line ((|string|)) at row ((|line|)) (default: current cursor
    position) and moves the cursor down one line.
=end
  class Buffer
    def filetype
      VIM::evaluate('&ft')
    end
    def newline
      VIM::command('normal o')
      #self.append($curbuf.row, "")
    end
    def append2(string, line=self.row)
      string.each do |str|
	self.append(line, str.chomp)
	VIM::command('normal j')
	line += 1
      end
    end
    alias_method :append_here, :append2

    # insert 'text' at row and col. If the latter two arguments aren't given,
    # the cursor position is used.
    def insert(text, row=self.row, col=self.col)
      str = self[row]
      str[col, 0] = text
      self[row] = str
    end
  end
end

