require 'dnssd'
require 'rest-client'
require 'nokogiri'
require 'nori'

# http://support.iridiummobile.net/uploaded/file/15553/1/5966/4780ba261138fa06297288fe6bc0fcc7.pdf
class BoseDevice
  def initialize(name, url)
    @name = name
    @url = url
  end

  def press(key)
    press = '<key state="press" sender="Gabbo">' + key + '</key>'
    release = '<key state="release" sender="Gabbo">' + key + '</key>'
    set('key', press)
    set('key', release)
    puts "press #{key}"
  end

  def bass
    get('bass')
  end

  def bass_capabilities
    get('bassCapabilities')
  end

  def volume=(target_volume)
    set('volume', "<volume>#{target_volume}</volume>")
  end

  def volume
    get('volume')
  end

  def now_playing
    get('now_playing')
  end

  def sources
    get('sources')
  end

  def track_info
    get('trackInfo')
  end

  def info
    get('info')
  end

  def presets
    get('presets')
  end

  def standby?
    get('now_playing')[:now_playing][:@source] == 'STANDBY'
  end

  def play
    press('PLAY')
  end

  def stop
    press('STOP')
  end

  def pause
    press('PAUSE')
  end

  def play_pause
    press('PLAY_PAUSE')
  end

  def previous_track
    press 'PREV_TRACK'
  end

  def next_track
    press 'NEXT_TRACK'
  end

  def mute
    press 'MUTE'
  end

  def volume_up
    press 'VOLUME_UP'
  end

  def volume_down
    press 'VOLUME_DOWN'
  end

  def preset=(number)
    press "PRESET_#{number}"
  end

  def input_aux
    press 'AUX_INPUT'
  end

  def shuffle=(state)
    press "SHUFFLE_#{state ? 'ON' : 'OFF'}"
  end

  def power_on
    press('POWER') if standby?
  end

  def power_off
    press('POWER') unless standby?
  end

  private

  @@parser = Nori.new(strip_namespaces: true, convert_tags_to: ->(tag) { tag.snakecase.to_sym })

  def get(action)
    target_url = @url + '/' + action
    response = RestClient.get(target_url)
    hash = @@parser.parse(response.body)
    puts "url #{target_url} : #{hash}"
    hash
  end

  def set(action, data)
    target_url = @url + '/' + action

    response = RestClient.post(target_url, data, accept: :xml, content_type: :xml)
    puts "url #{target_url} : #{data} #{response}"
    response
  end

  def to_s
    "#{@name} #{@url}"
  end
end

puts 'Starting discovery'
device = nil

services = {}
DNSSD.browse '_soundtouch._tcp' do |reply|
  services[reply.fullname] = reply

  services.sort_by do |_, service|
    [(service.flags.add? ? 0 : 1), service.fullname]
  end.each do |_, service|
    next unless service.flags.add?
    DNSSD.resolve service do |r|
      device = BoseDevice.new(r.name, "http://#{r.target}:#{r.port}")
    end
  end
end

sleep 3
#device.volume= 45
#device.now_playing
#device.presets
#device.sources
#device.bass
#device.bass_capabilities
#device.power_on
#device.preset = 5
#sleep 10
device.power_off
#sleep 4
# device.press("POWER")
