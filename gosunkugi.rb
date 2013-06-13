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
  end


  command(:pin,
          name: 'ピン留めする',
          condition: Plugin::Command[:HasOneMessage] & lambda{ |opt| opt.messages.first[:pinned] == nil },
          visible: true,
          role: :timeline) { |opt|
    opt.messages.each { |m| pin(m, true) }
  }

  command(:unpin,
          name: 'ピン留めを外す',
          condition: Plugin::Command[:HasOneMessage] & lambda{ |opt| opt.messages.first[:pinned] != nil },
          visible: true,
          role: :timeline) { |opt|
    opt.messages.each { |m| pin(m, false) }
  }


  filter_entity_linkrule_added { |rule|
    if rule[:slug] != :hashtags && rule[:slug] != :user_mentions
      rule = rule.dup
      callback = rule[:callback]

      rule[:callback] = lambda { |segment| 
        Plugin.UserConfig[:gosunkugi_auto_openurl] ||= false
        if Plugin.UserConfig[:gosunkugi_auto_openurl] then
          pin(segment[:message], true)
        end

        callback.call(segment)
      }

      rule.freeze
    end

    [rule]
  }

end
