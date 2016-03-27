require 'rrd'
require 'csv'
FILES = {
  "Concordia" => "concordiahospital.rrd",
  "Grace" => "gracehospital.rrd",
  "HSC-Adult" => "healthsciencescentreadult.rrd",
  "HSC-Childrens" => "healthsciencescentrechildrens.rrd",
  "7 Oaks" => "sevenoaksgeneralhospital.rrd",
  "St. B." => "stbonifacehospital.rrd",
  "Victoria" => "victoriageneralhospital.rrd" }

COLORS = %w[FFB300 803E75 FF6800 A6BDD7 C10020 CEA262 817066]
def to_file(name)
  name.tr("A-Z", 'a-z').gsub(/[^a-z]/, "")
end

def rrd_for(hospital)
  filename = "rrds/#{to_file(hospital)}.rrd"
  rrd = RRD::Base.new(filename)

  unless File.exists? filename
    rrd.create :start => Time.now - 2.days, :step => 5.minutes do
      datasource "people_waiting", :type => :gauge, :heartbeat => 20.minutes, :min => 0, :max => :unlimited
      datasource "average_wait", :type => :gauge, :heartbeat => 20.minutes, :min => 0, :max => :unlimited
      datasource "longest_wait", :type => :gauge, :heartbeat => 20.minutes, :min => 0, :max => :unlimited
      archive :average, :every => 5.minutes, :during => 1.week
      archive :average, :every => 1.hour, :during => 1.year
      archive :max, :every => 5.minutes, :during => 1.week
      archive :max, :every => 1.hour, :during => 1.year
    end
  end

  rrd
end

system "tail -1000 wrha_wait_times.csv > tmp.csv"

CSV.foreach("tmp.csv") do |row|
  rrd = rrd_for(row[1])
  rrd.update row[0], row[2], row[3], row[4]
end

RRD.graph! "all_hospitals.png", :title => "Hospital Emergency Queue Length", :width => 800, :height => 250, :start => Time.now - 1.day do
  FILES.each_with_index do |data, i|
    for_rrd_data "people_waiting#{i}", :people_waiting => :average, :from => "rrds/#{data[1]}"
    draw_line data: "people_waiting#{i}", color: "##{COLORS[i]}", label: "%-15s" % data[0], width: 1
    new_line = (i > 0 && i % 3 == 0) ? "\\n" : ""
    print_value "people_waiting#{i}:LAST", format: "%3.0lf%s#{new_line}"
  end
  print_comment "Updated at #{DateTime.now.strftime('%H\:%M %b %d, %Y')} UTC"
end
