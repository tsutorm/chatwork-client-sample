require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)


class Gaoon

  def initialize(api_key = nil)
    @api_key = api_key
  end

  def we_organization_ids()
    begin
      ids = ENV.fetch('MY_ORGANIZATION_IDS', '').split(',')
    rescue
      ids = []
    end

    ids << client.get_me()["organization_id"]
    ids.uniq
  end

  def contains_other_organization_members(we_org_ids, members)
    members.map { |m| m unless we_org_ids.include? m['organization_id'] }.compact
  end

  def collect_that_contains_other_organization_member_in_rooms(we_org_ids)
    rooms = client.get_rooms()
    puts "number of rooms: #{rooms.length}"
    rooms.map do |r|
      sleep 2
      room_id = r["room_id"]
      room_info =
        {
          room_id: room_id,
          room_name: r["name"],
        }
      begin
        members = client.get_members(room_id: room_id)
        room_info[:other_org_members] = contains_other_organization_members(we_org_ids, members)
      rescue ChatWork::APIError => e
        room_info[:other_org_members] = []
        room_info[:error] = e.message
      end
      print '.' # room_info.to_json
      room_info unless room_info[:other_org_members].empty?
    end.compact
  end

  def chatwork_api_key
    @api_key ||= ENV.fetch('CHATWORK_API_KEY', 'my_key')
  end

  def client
    @client ||= ChatWork::Client.new(api_key: chatwork_api_key)
  end

  def report
    room_info = collect_that_contains_other_organization_member_in_rooms(we_organization_ids)
    puts ""
    puts room_info.to_json
  end
end

Gaoon.new.report

