require 'nokogiri'
require 'open-uri'
require 'tzinfo'

def to_minutes(string)
  (hr, min) = string.split(/\s?:\s?/)
  hr.to_i * 60 + min.to_i
end

doc = Nokogiri::HTML(open('http://www.wrha.mb.ca/wait-times/'))

tz = TZInfo::Timezone.get('America/Winnipeg')
time = doc.css('td.DateTime').inner_text
time = Time.parse("#{time} #{tz.current_period.abbreviation}")

doc.css('tr td span.Facility').each do |hospital|
  row = hospital
  row = row.parent while row.name != "tr"
  (name, num_waiting, average_wait, _, longest_wait) = row.css('span').map(&:inner_text)
  puts "#{time.strftime("%s")},\"#{name}\",#{num_waiting},#{to_minutes average_wait},#{to_minutes longest_wait}"
end
