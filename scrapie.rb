#!/usr/bin/ruby

require 'httparty'
require 'json'

# Pastebin Scraper
#
class PastebinArchiver

  def initialize
    t = Time.now
    date = t.strftime("%Y%m%d")
    @filename = "./data/#{date}.json"
  end

  def store(new_pastes)

    # check if we have a file for today

    # if not, create it

    # then open the file
    existing_pastes = _get_all_pastes

    # then iterate through the new pastes and
    # add them together
    already_exists = false
    new_pastes.each do |np|
      existing_pastes.each do |ep|
        if ep["key"] == np["key"]
          already_exists = true
        end
      end

      unless already_exists
        existing_pastes << np
      end
    end

    # then update the file!
    File.open(@filename,"a").write(existing_pastes.to_json)

  end

  def all
    _get_all_pastes
  end

  private

    def _get_all_pastes
      begin
        JSON.parse(File.open(@filename,"r").read)
      rescue Errno::ENOENT => e # file didn't exist
        return []
      rescue JSON::ParserError => e
        return []
      rescue StandardError => e
        return []
      end
    end
end

# Pastebin Scraper
#
class PastebinScraper

    # Returns an array of posts from the pastebin API
    #
    # @return [Array] an array of paste data
    def scrape(limit=200)
      #key = ENV["PASTE_SCRAPER_KEY_PASTEBIN"]

      # Endpoint for latest posts
      new_posts_endpoint = "https://pastebin.com/api_scraping.php?limit=#{limit}"
      # Endpoint for each post
      post_endpoint = "https://pastebin.com/api_scrape_item.php?i=kYvG9T8x"
      post_metadata_endpoint = "https://pastebin.com/api_scrape_item_meta.php?i=kYvG9T8x"
      pastes_endpoint = "https://pastebin.com/api_scraping.php?limit=250"

      begin
        response = HTTParty.get new_posts_endpoint
        posts = JSON.parse(response.body)
        puts "[+] GOT #{posts.count} pastes"

        posts.each do |p|
          puts p["scrape_url"]
          paste_response = HTTParty.get(p["scrape_url"])
          paste = paste_response.body
          p["text"] = _encode_string(paste)
        end

      rescue JSON::ParserError => e
        puts "Unable to get parsable response: #{e}"
      rescue StandardError => e
        puts "Error grabbing new pastes: #{e}"
      end

    posts

    end

  private

    def _encode_string(string)
      return string unless string.kind_of? String
      string.encode("UTF-8", :undef => :replace, :invalid => :replace, :replace => "?")
    end

end

scraper = PastebinScraper.new
archive = PastebinArchiver.new

posts = scraper.scrape(2)
archive.store(posts)

puts "Holding #{archive.all.count} pastes!"
