# -*- coding: utf-8 -*-

Plugin.create :gosunkugi do 
  def pin(msg, pinning)
    if pinning then
      msg[:modified] = Time.new + 1000000
      msg[:pinned] = "pinned"
    else
      msg[:modified] = Time.new
      msg[:pinned] = nil
    end

    Plugin::call(:message_modified, msg)

    msg
  end

  settings "ピン留め" do
    settings "自動ピン留め" do
      boolean("URLを開いたとき", :gosunkugi_auto_openurl)
    end

    settings "カスタムスタイル" do
      boolean("カスタムスタイルを使う", :gosunkugi_custom_style)
      fontcolor("フォント", :gosunkugi_font_face, :gosunkugi_font_color)
      color("背景色", :gosunkugi_background_color)
    end
  end

  on_boot { |service|
    UserConfig[:gosunkugi_auto_openurl] ||= false
    UserConfig[:gosunkugi_custom_style] ||= false
    UserConfig[:gosunkugi_font_color] ||= [0, 0, 0]
    UserConfig[:gosunkugi_background_color] ||= [220 * 256, 220 * 256, 180 * 256]
  }

  command(:pin,
          name: 'ピン留めする',
          condition: Plugin::Command[:HasOneMessage] & lambda{ |opt| opt.messages.first[:pinned] == nil },
          icon: File.dirname(__FILE__) + "/a20-8.png",
          visible: true,
          role: :timeline) { |opt|
    opt.messages.each { |m| pin(m, true) }
  }

  command(:unpin,
          name: 'ピン留めを外す',
          condition: Plugin::Command[:HasOneMessage] & lambda{ |opt| opt.messages.first[:pinned] != nil },
          icon: File.dirname(__FILE__) + "/a20-8.png",
          visible: true,
          role: :timeline) { |opt|
    opt.messages.each { |m| pin(m, false) }
  }


  filter_message_background_color { |message, color|
    if UserConfig[:gosunkugi_custom_style] && message.message[:pinned] then
      color = UserConfig[:gosunkugi_background_color]
    end

    [message, color]
  }

  filter_message_font_color { |message, color|
    if UserConfig[:gosunkugi_custom_style] && message.message[:pinned] then
      color = UserConfig[:gosunkugi_font_color]
    end

    [message, color]
  }

  filter_message_font { |message, font|
    if UserConfig[:gosunkugi_custom_style] && message.message[:pinned] then
      font = UserConfig[:gosunkugi_font_face]
    end

    [message, font]
  }


  filter_entity_linkrule_added { |rule|
    if rule[:slug] != :hashtags && rule[:slug] != :user_mentions
      rule = rule.dup
      callback = rule[:callback]

      rule[:callback] = lambda { |segment| 
        UserConfig[:gosunkugi_auto_openurl] ||= false
        if UserConfig[:gosunkugi_auto_openurl] && segment[:message] then
          pin(segment[:message], true)
        end

        callback.call(segment)
      }

      rule.freeze
    end

    [rule]
  }

end
