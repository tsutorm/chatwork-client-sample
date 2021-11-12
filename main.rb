require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)

def we_organization_ids(client)
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

def collect_that_contains_other_organization_member_in_rooms(client, we_org_ids)
  rooms = client.get_rooms()
  rooms.map do |r|
    sleep 2
    room_id = r["room_id"]
    members = client.get_members(room_id: room_id)
    other_org_members = contains_other_organization_members(we_org_ids, members)
    room_info =
      {
        room_id: room_id,
        room_name: r["name"],
        other_org_members: other_org_members
      }
    p room_info
    room_info unless other_org_members.empty?
  end.compact
end

def chatwork_api_key
  ENV.fetch('CHATWORK_API_KEY', 'my_key')
end

def main
  client = ChatWork::Client.new(api_key: chatwork_api_key)
  p collect_that_contains_other_organization_member_in_rooms(client, we_organization_ids(client)).to_json
end

main
