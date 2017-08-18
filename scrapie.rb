#!/usr/bin/ruby

require 'httparty'
require 'json'

# Pastebin Scraper
#
class PastebinArchiver

  def initialize
    date = Time.now.strftime("%Y%m%d")
    @filename = "./data/#{date}.json"
  end

  def store(new_pastes)

    # then open the file
    existing_pastes = _get_all_pastes

    begin
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
    rescue NoMethodError => e
      puts "[-] Error with the response... rate limiting? #{e}"
    end

  end

  def all
    _get_all_pastes
  end

  private

    def _get_all_pastes
      begin
        pastes = JSON.parse(File.open(@filename,"r").read)
      rescue Errno::ENOENT => e # file didn't exist
        puts "[-] Error: #{e}"
        return []
      rescue JSON::ParserError => e
        puts "[-] Error: #{e}"
        return []
      rescue StandardError => e
        puts "[-] Error: #{e}"
        return []
      end
    pastes
    end
end

# Pastebin Scraper
#
class PastebinScraper

    # Returns an array of posts from the pastebin API
    #
    # @return [Array] an array of paste data
    def scrape(limit=200)

      # Endpoint for latest posts
      new_pastes_endpoint = "https://pastebin.com/api_scraping.php?limit=#{limit}"

      begin
        response = HTTParty.get new_pastes_endpoint
        posts = JSON.parse(response.body)
        puts "[+] Go #{posts.count} pastes"

        posts.each do |p|
          #puts p["scrape_url"]
          paste_response = HTTParty.get(p["scrape_url"])
          paste = paste_response.body
          p["text"] = _encode_string(paste)
        end

      rescue JSON::ParserError => e
        puts "[-] Unable to get parsable response: #{e}"
      rescue StandardError => e
        puts "[-] Error grabbing new pastes: #{e}"
      end

    posts

    end

  private

    def _encode_string(string)
      return string unless string.kind_of? String
      string.force_encoding("ISO-8859-1").encode("UTF-8")
    end

end

scraper = PastebinScraper.new
archive = PastebinArchiver.new

posts = scraper.scrape(250)
archive.store(posts)

puts "[+] Holding #{archive.all.count} pastes!"
