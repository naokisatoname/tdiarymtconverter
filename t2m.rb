#!/usr/bin/env ruby
require "time"

AUTHOR="hogehoge"

#画像の移行を行うばあいは設定必須
IMAGE_URL="/images"

module WikiStyle
  def style_init
    puts "WikiStyle"
    @ul_switch = 0
    @tablemode = 0
  end

  def end_body
    while @ul_switch > 0
      @body[@diary_key] += "</ul>\n"
      @ul_switch -= 1
    end
    @body[@diary_key] += "</p>\n"
  end

  def read_body(line)
    if line =~ /^!([^!]+)/
      # カテゴリ行 (独自ルール)
      tmp = $1
      if (tmp =~ /\[([^\]]*)\](.*)/)
        category = $1
      else
        category = ""
      end

      title = @_title

      next_title(title, category)
      @body[@diary_key] += "<p>"
    else
      if line == ""
        @body[@diary_key] += "</p>\n<p>"
        return
      end

      if line =~ /^\s/
        line = "<pre>" + $' + "</pre>"
      end

      if line =~ /^!!([^!]+)/
        line = "<h4>" + $1 + "</h4>"
      end

      if line =~ /^!!!([^!]+)/
        line = "<h5>" + $1 + "</h5>"
      end

      while line =~ /{{'([^']+)'}}/
        line = $` + $1 + $'
      end

      if line =~ /'''([^']+)'''/
        line = $` + "<strong>" + $1 + "</strong>" + $'
      end

      if line =~ /''([^']+)''/
        line = $` + "<em>" + $1 + "</em>" + $'
      end

      if line =~ /==(.+)==/
        line = $` + "<del>" + $1 + "</del>" + $'
      end

      # table
      if line =~ /^\|\|/
        if @tablemode == 0
          @body[@diary_key] += "<table border='2'>\n"
        end
        cols = line.split(/\|\|/)
        cols.shift
        line = "<tr>"
        for col in cols
          line += "<td>" + col + "</td>"
        end
        line += "</tr>"
        @tablemode = 1
      elsif @tablemode != 0
        @body[@diary_key] += "</table>\n"
        @tablemode = 0
      end

      # replace a hyperlink
      if (line =~ /\[\[(.*)\s*\|(.*)\]\]/)
        line = $` + "<a href=\"" + $2 + "\">" + $1 + "</a>" + $'
      end

      if (@ul_switch > 0 && line =~ /^[^\*]/)
        while @ul_switch > 0
          @body[@diary_key] += "</ul>\n"
          @ul_switch -= 1
        end
      end
      if (line =~ /^(\*+)([^\*]*)/)
        switches = $1.size

        while @ul_switch < switches
          @body[@diary_key] += "<ul>\n"
          @ul_switch += 1
        end

        while @ul_switch > switches
          @body[@diary_key] += "</ul>\n"
          @ul_switch -= 1
        end

        line = "<li>" + $2 + "</li>"
      end

      # 日記本体
      #  <%=image 0, '川べり　ここに写ってないけど、久々にすずめをみたよ。', nil, [256,192]%>
      #  <%=image 1, '職場からの東京(昼)その1'%>
      # for 画像対応
      # 20040413_0.jpg

      regexp = /\<\%=image\s+([\d]+),\s*'(.*)'\s*(,\s*([^\[]*)\s*,\s*(.*)\s*)?\%\>/
      if (line =~ regexp )
        print "image\n" if $DEBUG
        print "$1, $2, $3,$4,\n" if $DEBUG
        image_key = $1
        alt = $2
        op = $3
        wh = $5

        image_name ="#{@date_string}_#{image_key}.jpg"
        print "$image_name\n" if $DEBUG

        if(wh != "")
          wh =~ /\[\s*([\d]+)\s*,\s*([\d]+)\s*\]/
          width = $1
          height = $2
        else
          width=-1
          height=-1
        end

        line.gsub!(regexp,"\<img alt=\"#{alt}\" src=\"#{IMAGE_URL}\/#{image_name}\" width=#{width} height=#{height} border=\"0\"\/>")
      end

      regexp = /{{image\s+([\d]+),\s*'(.*)'\s*,\s*nil\s*,\s*(.*)\s*}}/
      if (regexp.match(line) )
        print "image\n" if $DEBUG
        print "$1, $2, $3,$4,\n" if $DEBUG
        image_key = $1
        alt = $2
        wh = $3

        image_name ="#{@date_string}_#{image_key}.jpg"
        print "$image_name\n" if $DEBUG

        if(wh != "")
          wh =~ /\[\s*([\d]+)\s*,\s*([\d]+)\s*\]/
          width = $1
          height = $2
        else
          width=-1
          height=-1
        end

        line.gsub!(regexp,"\<img alt=\"#{alt}\" src=\"#{IMAGE_URL}\/#{image_name}\" width=#{width} height=#{height} border=\"0\"\/>")
      end

      if tmp
        @body[@diary_key] += tmp + "\n"
      else
        @body[@diary_key] += line + "\n"
      end
    end

  end
end

module TDiaryStyle
  def style_init
    puts "TDiaryStyle"
    @blank = true
  end

  def read_body(line)
    if @blank
      # 空行の次だったのでタイトルとして使用
      if (line =~ /\[([^\]]*)\](.*)/)
        category = $1
        title = $2
      else
        category = ""
        title = line
      end

      next_title(title, category)

      @blank = false
    else

      if line == ""
        @blank = true
      else
        # 日記本体
        #  <%=image 0, '川べり　ここに写ってないけど、久々にすずめをみたよ。', nil, [256,192]%>
        #  <%=image 1, '職場からの東京(昼)その1'%>
        # for 画像対応
        # 20040413_0.jpg

        regexp = /\<\%=image\s+([\d]+),\s*'(.*)'\s*(,\s*([^\[]*)\s*,\s*(.*)\s*)?\%\>/
        if (line =~ regexp )
          print "image\n" if $DEBUG
          print "$1, $2, $3,$4,\n" if $DEBUG
          image_key = $1
          alt = $2
          op = $3
          wh = $5

          image_name ="#{@date_string}_#{image_key}.jpg"
          print "$image_name\n" if $DEBUG

          if(wh != "")
            wh =~ /\[\s*([\d]+)\s*,\s*([\d]+)\s*\]/
            width = $1
            height = $2
          else
            width=-1
            height=-1
          end

          line.gsub!(regexp,"\<img alt=\"#{alt}\" src=\"#{IMAGE_URL}\/#{image_name}\" width=#{width} height=#{height} border=\"0\"\/>")
        end

        regexp = /{{image\s+([\d]+),\s*'(.*)'\s*,\s*nil\s*,\s*(.*)\s*}}/
        if (regexp.match(line) )
          print "image\n" if $DEBUG
          print "$1, $2, $3,$4,\n" if $DEBUG
          image_key = $1
          alt = $2
          wh = $3

          image_name ="#{@date_string}_#{image_key}.jpg"
          print "$image_name\n" if $DEBUG

          if(wh != "")
            wh =~ /\[\s*([\d]+)\s*,\s*([\d]+)\s*\]/
            width = $1
            height = $2
          else
            width=-1
            height=-1
          end

          line.gsub!(regexp,"\<img alt=\"#{alt}\" src=\"#{IMAGE_URL}\/#{image_name}\" width=#{width} height=#{height} border=\"0\"\/>")
        end

        @body[@diary_key] += line + "\n"

      end
    end
  end

end



class TDiaryReader

  attr_reader :category, :title, :visible, :body, :date
  attr_reader :c_body, :c_author, :comments, :c_track, :c_visible, :c_ping_body, :c_ping_title, :c_blog_title, :c_url, :c_mail, :c_date

  def initialize
    @category = {}
    @title = {}
    @visible = {}
    @body = {}
    @date = {}
    @key = 0
    @comments = {}
    @c_body = {}
    @c_author = {}
    @c_track = {}
    @c_visible = {}
    @c_ping_body = {}
    @c_ping_title = {}
    @c_blog_name= {}
    @c_url = {}
    @c_mail = {}
    @c_date = {}
  end

  def read_body(line)
  end

  def end_body
  end


  def style_init
  end

  def next_title(title,category)
    puts @title.inspect
    # 空行の次だったのでタイトルとして使用
    @key+=1
    @diary_key = "#{@date_string}-#{@key}"
    #    puts @diary_key

    @category[@diary_key] = category
    @title[@diary_key] = title

    p_date_time = sprintf("%s 12:00:%02d PM", @p_date, @key)
    @date[@diary_key] = p_date_time
    @body[@diary_key] = ""
    @visible[@diary_key] = @visible_article
  end

  #------------------------------
  # td2の読み込み。
  #------------------------------
  # 使用するkey
  # $diary_key = "${date}-${key}"

  # === つかうHash
  # $title{$diary_key}
  # $date{$diary_key}
  # $body{$diary_key}
  def read_tdiary(filename)

    file = File.open(filename)
    content_switch = 0
    ul_switch=0
    @date_string = ""
    @key = 0
    @diary_key = ""
    @visible_article = true
    p_date = ""

    file.each_line do |line|
      line.chomp!

      if content_switch == 0
        if(line =~ /TDIARY2/)
        elsif(line =~ /^$/)
          # 空の行。次の行はTitle
          content_switch=1
        elsif(line =~ /^Format: ([^\s]+)/)
          if $1 == "Wiki"
            self.extend WikiStyle
          elsif $1 == "tDiary"
            self.extend TDiaryStyle
          end

          style_init
          # 意味無の行。ただし、Headerのさいご
        elsif(line =~ /Date: ([\w]+)/)
          # 日付けを読み込む。
          if(@date_string == $1)
            @key+=1
          else
            @key=0
          end
          @date_string = $1
          @diary_key = "#{@date_string}-#{@key}"
          @date_string =~/([\d][\d][\d][\d])([\w][\w])([\w][\w])/
          year = $1.to_i
          mon = $2.to_i
          day = $3.to_i

          # MTの日付け書式に変換
          @p_date = sprintf("%02d/%02d/%02d", mon, day, year)
          @body[@diary_key] = ""
        elsif(line =~ /Title: (.*)/)
          @_title = $1
          #	    $title{$diary_key}=$1
        elsif(line =~ /Last-Modified/)
          # 無視
        elsif(line =~ /^Visible: (.*)/)
          if($1 =~ /true/)
            @visible_article=true
          else
            @visible_article=false
          end

          # 無視
        end
      else
        if (line =~ /^.$/)
          # 日付終了記号
          content_switch=0
          end_body
        else
          read_body(line)
        end
      end
    end
    file.close
  end
  #--------------------------------------------------------------
  # commnet,trackback読み込み
  #--------------------------------------------------------------
  # comment部分とtrackbackは同じ書式で記録されているので共通。
  #
  # commentの日付については、Last-Modifiedのデータを使用する。
  # 読み取りデータ
  # 使用するkey
  #  $c_diary_key = "${c_date}-${c_key}-C"

  # ==== つかうHash
  # $c_track{$c_diary_key}
  # $c_author{$c_diary_key}
  # $c_mail{$c_diary_key}
  # $c_date{$c_diary_key}
  # $c_body{$c_diary_key}

  #track back用
  # $c_url{$c_diary_key}
  # $c_blog_name{$c_diary_key}
  # $c_ping_title{$c_diary_key}
  # $c_ping_body{$c_diary_key}
  def read_comment(filename)
    puts filename

    file = File.open(filename)
    c_title_switch = 0
    read_blog_switch = 0
    read_ping_title = 0
    read_ping_body = 0
    c_diary_key = ""
    c_date = ""
    track_back = 0
    c_key = 0

    file.each_line do |line|
      line.chomp!
      if(line =~ /TDIARY2/)
      elsif(line =~ /^.$/)
        # 日付終了記号
      elsif(line =~ /^$/)
        # 空の行。
      elsif(line =~ /^Format: /)
        # 意味無の行。ただし、Headerの最後
      elsif(c_title_switch==2)
        # Headerの次のぎょうは空行。何もしない。
      elsif(line =~ /Date: ([\w]+)/)
        # 日付けを読み込む。
        track_back=0
        if(c_date == $1)
          c_key+=1
        else
          c_key=1
        end
        c_date = $1
        c_diary_key = "#{c_date}-#{c_key}-C"

        # コメントと日付けの紐づけを間単にする。
        diary_key = "#{c_date}-1"

        if @comments[diary_key]
          @comments[diary_key].push(c_diary_key)
        else
          @comments[diary_key] = [c_diary_key]
        end

        @c_body[c_diary_key] = ""
        @c_author[c_diary_key] = ""
        @c_track[c_diary_key] = ""
        @c_visible[c_diary_key] = 0
        @c_ping_body[c_diary_key] = ""
        @c_ping_title[c_diary_key] = ""
        @c_blog_name[c_diary_key] = ""
        @c_url[c_diary_key] = ""
        @c_mail[c_diary_key] = ""
      elsif(line =~ /Name: (.*)/)
        name = $1

        if ( name == "TrackBack" )
          track_back=1
          @c_track[c_diary_key] = 1
        else
          track_back=0
          read_ping_body=0
          @c_track[c_diary_key] = 0
        end
        @c_author[c_diary_key] = name

      elsif(line =~ /Mail: (.*)/)
        @c_mail[c_diary_key] = $1
      elsif(line =~/Last-Modified: ([\w]+)/)
        my_dt = $1.to_i
        puts my_dt
        sec, min, hour, mday, mon, year, wday, yday, isdst, zone = Time.at(my_dt).to_a
        if (hour > 12 )
          ampm="PM"
          hour -=12
        else
          ampm="AM"
        end
        #$c_p_date= "$wday/$mon/$year $hour:$min:$sec $ampm"
        c_p_date= sprintf("%02d/%02d/%04d %02d:%02d:%02d %s", mon, mday, year, hour, min, sec, ampm)

        @c_date[c_diary_key]=c_p_date
      elsif(line =~ /^Visible: (.*)/)
        if($1 == "true")
          @c_visible[c_diary_key]=1
        else
          @c_visible[c_diary_key]=0
        end
        puts "C #{@c_visible[c_diary_key]}"
      else
        # 日記本体
        # TrackBackのため条件分岐

        if(track_back==1)
          if(line =~ /http:/)
            @c_url[c_diary_key] = line
            read_blog_switch=1
          elsif(read_blog_switch==1)
            @c_blog_name[c_diary_key]=line
            read_blog_switch=0
            read_ping_title=1
          elsif(read_ping_title==1)
            @c_ping_title[c_diary_key]=line
            read_ping_title=0
            read_ping_body=1
          elsif(read_ping_body==1)
            @c_ping_body[c_diary_key] += line
          end
        else
          @c_body[c_diary_key] += line + "\n"
        end
      end
    end

    file.close
  end


  #---------------------------
  # log2mt.logの本体部分出力
  #---------------------------
  def print_body(file, key)
    file.print <<"__DIARY_FST__"
AUTHOR: #{AUTHOR}
TITLE: #{@title[key]}
STATUS: Publish
ALLOW COMMENTS: 1
CONVERT BREAKS: __default__
ALLOW PINGS: 1
__DIARY_FST__

    if @category[key] != ""
      categories = @category[key].split(",")

      file.puts "PRIMARY CATEGORY: #{categories[0]}"

      for category in categories
        file.puts "CATEGORY: #{category}"
      end
    else
      file.print "PRIMARY CATEGORY: \n"
    end
    file.print <<"__DIARY_SND__"

DATE: #{@date[key]}
-----
BODY:
#{@body[key]}
-----
EXTENDED BODY:

-----
EXCERPT:

-----
KEYWORDS:

-----
__DIARY_SND__
  end

  #------------------------------
  # log2mt.logのコメント部分出力
  #------------------------------
  def print_comment(file, key)
    file.print <<"__COMMENT__"
COMMENT: 
AUTHOR: #{@c_author[key]}
EMAIL: #{@c_mail[key]}
IP: 
URL: 
DATE: #{@c_date[key]}
#{@c_body[key]}

-----
__COMMENT__
  end

  #---------------------------------
  # log2mt.logのTrackBack部分出力
  #---------------------------------
  def print_ping(file, key)
    puts "#{key}"
    puts "#{@c_url[key]}"
    file.print <<"__PING__"

PING: 
TITLE: #{@c_ping_title[key]}
URL: #{@c_url[key]}
IP: 
BLOG NAME: #{@c_blog_name[key]}
DATE: #{@c_date[key]}
#{@c_ping_body[key]}

-----
__PING__
  end

  def print_end(file)
    file.print "\n\n--------\n"
  end
end


require 'pathname'
#========#
#  Main  #
#========#

# 日記読み込み
# check options
#if ($opt_d == "")
#  print "usage t2m.pl -d [log file] (without c, or 2)\n"
#  print "  example Target file 200405.td2, 200405.tdc   then [log file] is 200405.td\n"
#  exit 1
#end

combinedfile = File.open("mt-export.txt", "w")


Dir.glob("*/*.td2").each do |td2filename|
  reader = TDiaryReader.new
  puts "convert #{td2filename}"
  tdcfilename = Pathname(td2filename).sub_ext('.tdc').to_s
  outputfilename = Pathname(td2filename).sub_ext('.log').to_s

  reader.read_tdiary(td2filename)
  #reader.read_comment(tdcfilename) if File.exist?(tdcfilename)

  outputfile = File.open(outputfilename, "w+")
  target_list = reader.title.keys.sort
  for key in target_list
    if(reader.visible[key])
      reader.print_body(outputfile, key)

      if reader.comments[key]
        # print つっこみ
        for c_key in reader.comments[key]
          if(reader.c_visible[c_key]==1)
            if(reader.c_track[c_key] == 0)
              reader.print_comment(outputfile, c_key)
            else
              reader.print_ping(outputfile, c_key)
            end
          end
        end
      end
      reader.print_end(outputfile)
    end
  end

  outputfile.seek(0)
  combinedfile.write(outputfile.read)
  outputfile.close
end


combinedfile.close

