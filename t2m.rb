#!/usr/bin/env ruby
require "time"


# 前提知識
#  tdiaryのログはdata_pathの下にファイルがあります。
#  ファイル
#   200405.td2 : 日記ファイルのデータ本体
#   200405.tdc : ツッコミデータ ( TrackBackデータも存在 )
#
# 使いかた
#  上記データファイルがカレントディレクトリにある時だけ、動作確認をしています。
#
#  t2m.pl -d [log file] {-n [date]}  {-g}
#   [log file]は、最後の文字(2やc)を除いたファイル名を指定。
#   200405.tdc, 200405.td2の場合は, 200405.tdを指定
#
#   [date] この日付けを指定し、これよりも新しい日付けの日記にたいして処理を行わせる
#    書式例: 20040101
#

AUTHOR="kacky"

#画像の移行を行うばあいは設定必須
TDIARY_IMAGES_DIR="/home/kenstar/public_html/tdiary/images"
MT_IMAGE_DIR="/home/kenstar/public_html/ks/archives"
IMAGE_URL="/~kenstar/ks/archives"

#use Getopt::Std;
#use File::Copy;

#getopt("d:n:g");

module WikiStyle
  def style_init
    puts "WikiStyle"
    @ul_switch = 0
  end
  def read_body(line)
    if line =~ /^!([^!]+)/
      # タイトル行
      tmp = $1
      if (tmp =~ /\[([^\]]*)\](.*)/)
        category = $1
        title = $2
      else
        category = ""
        title = tmp
      end
      
      next_title(title, category)
    else
      # replace a hyperlink
      if (line =~ /\[\[(.*)\s*\|(.*)\]\]/)
        tmp = "<a href=\"" + $2 + "\">" + $1 + "</a>"
      end
      
      if (@ul_switch != 0 && line =~ /^[^\*]/) 
        @ul_switch = 0
        @body[@diary_key] += "</ul>\n<p>"
      end
      if (line =~ /^\*\s+(.*)/)
        if (@ul_switch == 0) 
          @ul_switch = 1
          @body[@diary_key] += "</p>\n<ul>\n"
        end
        
        line = "<li>" + $1 + "</li>"
      end
      
      @body[@diary_key] += line + "\n"
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
      # replace a hyperlink
      if (line =~ /\[\[(.*)\s*\|(.*)\]\]/)
        tmp = $1
      end
      if (tmp =~ /\[([^\]]*)\](.*)/)
        category = $1
        title = $2
      else
        category = ""
        title = tmp
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
          
          image_name ="#{date}_#{image_key}.jpg"
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
          # File.copy("#{TDIARY_IMAGES_DIR}/#{image_name}", "#{MT_IMAGE_DIR}") or print "cannot copy\n"
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
    file.print <<"__DIARY_CATEGORY__"
PRIMARY CATEGORY: #{@category[key]}
CATEGORY: #{@category[key]}
__DIARY_CATEGORY__
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

Dir.glob("*/*.td2").each do |td2filename|
  reader = TDiaryReader.new
  puts "convert #{td2filename}"
  tdcfilename = Pathname(td2filename).sub_ext('.tdc').to_s
  outputfilename = Pathname(td2filename).sub_ext('.log').to_s
  
  reader.read_tdiary(td2filename)
  reader.read_comment(tdcfilename) if File.exist?(tdcfilename)
  
  outputfile = File.open(outputfilename, "w")
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
end


=begin
puts reader.visible.inspect

target_list = reader.title.keys.sort

for key in target_list
  print "D key : $title{$key}\n" if $DEBUG2
  print "D date{$key}\n" if $DEBUG2
  print "D body{$key}\n" if $DEBUG2
  if(reader.visible[key]==1)
    print_body(reader.title[key], reader.date[key], reader.body[key], reader.category[key])
    
    if reader.comments[key]
      # print つっこみ
      for c_key in reader.comments[key]
        if(reader.c_visible[c_key]==1)
          if(reader.c_track[c_key] == 0)
            print_comment(reader.c_author[c_key], reader.c_mail[c_key], reader.c_date[c_key], reader.c_body[c_key], "","" )
            #	        &print_comment($c_author{$c_key}, $c_mail{$c_key}, $c_date{$c_key}, $c_body{$c_key}, $c_ip{$c_key},$c_url{$c_key} )
          else
            print_ping(reader.c_ping_title[c_key], reader.c_url[c_key], reader.c_blog_name[c_key], reader.c_date[c_key], reader.c_ping_body[c_key], "")
          end
        end
        print "D $c_key : $c_author{$c_key} : $c_mail{$c_key} : $c_date{$c_key}\n" if $DEBUG2
        print "D $c_body{$c_key}\n" if $DEBUG2
      end
    end
    print_end
  end
end
=end