require 'net/http'
require 'json'

class GithubActivity
  BASE_URL = "https://api.github.com"

  def initialize(username)
    @username = username
  end

  def user_events
    url = URI("#{BASE_URL}/users/#{@username}/events/public")
    res = Net::HTTP.get_response(url)
    raise "Failed to fetch events (#{res.code})" unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body)
  end

  def analyze
    grouped = {}

    user_events.each do |event|
      repo = event["repo"]["name"]
      type = event["type"]
      grouped[repo] ||= []
      grouped[repo] << type
    end

    grouped.map do |repo, types|
      {
        repo: repo,
        top_events: types.tally.sort_by { |_, c| -c }.first(3).to_h,
        owned_by_user: repo.start_with?("#{@username}/")
      }
    end
  end

  def print_summary
    puts "\nGitHub activity for username: #{@username}"
    puts "----------------------------------"

    analyze.each do |r|
      puts "\nRepo: #{r[:repo]}"
      puts "Top event types:"
      r[:top_events].each { |t, c| puts "  - #{t}: #{c}" }
      puts "Is repo owned by user: #{r[:owned_by_user] ? 'Yes' : 'No'}"
      puts "-" * 30
    end
  end
end


username = 'ge0ffrey'
begin
  GithubActivity.new(username).print_summary
rescue => e
  puts "Error: #{e.message}"
end
