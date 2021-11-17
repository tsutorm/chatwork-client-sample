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

  def contains_other_organization_members(we_org_ids, members, expected_keys=nil)
    members.map do |m|
      unless we_org_ids.include? m['organization_id']
        expected_keys ? m.slice(*expected_keys): m
      end
    end.compact
  end

  def contains_we_organization_admin_members(we_org_ids, members,expected_keys=nil)
    members.map do |m|
      if we_org_ids.include? m['organization_id'] and m['role'] == 'admin'
        expected_keys ? m.slice(*expected_keys): m
      end
    end.compact
  end

  def regroup_we_or_others(we_org_ids, members)
    {
      other_org_members: contains_other_organization_members(we_org_ids, members, ['chatwork_id', 'name', 'organization_name', 'department']),
      we_org_members: contains_we_organization_admin_members(we_org_ids, members, ['name'])
    }
  end

  def collect_that_contains_other_organization_member_in_rooms(we_org_ids)
    rooms = client.get_rooms()
    puts "number of rooms: #{rooms.length}"
    rooms[1..50].map do |r|
      sleep 2
      room_id = r["room_id"]
      room_info =
        {
          room_id: room_id,
          room_name: r["name"],
        }
      begin
        members = client.get_members(room_id: room_id)
        room_info[:members] = regroup_we_or_others(we_org_ids, members)
      rescue ChatWork::APIError => e
        room_info[:members] = {other_org_members: [], we_org_members: []}
        room_info[:error] = e.message
      end
      print '.'
      # puts room_info.to_json
      # puts ''
      room_info unless room_info[:members][:other_org_members].empty?
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

