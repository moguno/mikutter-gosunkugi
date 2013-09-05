# -*- coding: utf-8 -*-

class Message
  alias retweet_org retweet
  alias favorite_org favorite

  def retweet
    if retweetable?
      Plugin.call(:do_retweet, self)
      self.service.retweet(self){|*a| yield *a if block_given? } if self.service end end

  def favorite(fav = true)
    if favoritable?
      Plugin.call(:do_favorite, self)
      self.service.favorite(self, fav) end end
end

Plugin.create :gosunkugi do 
  on_do_favorite { |msg|
    if UserConfig[:gosunkugi_auto_unpin_favorite]
      if msg[:pinned]
        pin(msg, false)
      end
    end
  }

  on_do_retweet { |msg|
    if UserConfig[:gosunkugi_auto_unpin_retweet]
      if msg[:pinned]
        pin(msg, false)
      end
    end
  }

  def pin(msg, pinning)
    if pinning then
      msg[:modified] = Time.new + 1000000
      msg[:pinned] = "pinned"

      if UserConfig[:gosunkugi_auto_unpin_time]
        Reserver.new(UserConfig[:gosunkugi_auto_unpin_sec]) {
          pin(msg, false)
	}
      end
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

    settings "自動ピン留め解除" do
      boolean("一定時間が経過したとき", :gosunkugi_auto_unpin_time)
      adjustment("　一定時間（秒）", :gosunkugi_auto_unpin_sec, 1, 10000000)
      boolean("リツイートしたとき", :gosunkugi_auto_unpin_retweet)
      boolean("ふぁぼふぁぼしたとき", :gosunkugi_auto_unpin_favorite)
    end

    settings "カスタムスタイル" do
      boolean("カスタムスタイルを使う", :gosunkugi_custom_style)
      fontcolor("フォント", :gosunkugi_font_face, :gosunkugi_font_color)
      color("背景色", :gosunkugi_background_color)
    end
  end

  on_boot { |service|
    UserConfig[:gosunkugi_auto_openurl] ||= false
    UserConfig[:gosunkugi_auto_unpin_time] ||= false
    UserConfig[:gosunkugi_auto_unpin_retweet] ||= false
    UserConfig[:gosunkugi_auto_unpin_favorite] ||= false
    UserConfig[:gosunkugi_auto_unpin_sec] ||= 300
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
