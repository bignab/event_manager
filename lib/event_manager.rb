# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

puts 'Event Manager Initialized'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0').slice(0, 5)
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    # legislators = legislators.officials
    # legislator_names = legislators.map(&:name)
    # legislator_names.join(', ')
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end

def clean_phone_number(phone_number)
  clean_phone_number = phone_number.gsub(/[-().+a-zA-Z]/, '')
  if clean_phone_number.length < 10 || clean_phone_number.length > 11
    "Invalid number"
  elsif clean_phone_number.length == 11
    if clean_phone_number[0] == '1'
      clean_phone_number.slice(1, clean_phone_number.length)
    else
      "Invalid number"
    end
  else
    clean_phone_number
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislator = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  puts "#{name} #{phone_number}"
  save_thank_you_letter(id, form_letter)
end
