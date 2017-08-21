#!/usr/bin/ruby

require 'httparty'
require 'json'

# Pastebin Scraper
#
class PastebinArchiver

  def initialize
    date = Time.now.strftime("%Y%m%d")
    @data_path = "./data"
    @file_base = "#{@data_path}/#{date}"

    # these two are used to store the index and data
    @current_index_file_path = "#{@file_base}.json"
    @current_data_directory = "#{@file_base}"

    # make a directory if it doesn't already exist
    Dir.mkdir "#{@current_data_directory}" unless File.exists?(@current_data_directory)

  end

  def fetch_and_store(new_pastes)

    # then open the file
    existing_pastes = _get_all_pastes
    overlapping_paste_count = 0

    begin
      # then iterate through the new pastes and
      # add them together
      already_exists = false
      new_pastes.each do |np|
        #puts "Checking new paste: #{np["key"]}"
        existing_pastes.each do |ep|
          if ep["key"] == np["key"]
            overlapping_paste_count += 1
            already_exists = true
          end
        end

        unless already_exists
          store_location = "#{@current_data_directory}/#{np["key"]}.txt"
          File.open(store_location,"w").write(np["text"])
          np.delete("text")
          np["file"] = store_location
          existing_pastes << np
        end

      end

      puts "[+] #{overlapping_paste_count} overlapping pastes in this run."

      # Then update the file!
      File.open("#{@current_index_file_path}","w+").write(existing_pastes.to_json)
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
        pastes = JSON.parse(File.open("#{@current_index_file_path}","r").read)
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
    def scrape(limit=250)

      # Endpoint for latest posts
      new_pastes_endpoint = "https://pastebin.com/api_scraping.php?limit=#{limit}"

      begin
        response = HTTParty.get new_pastes_endpoint
        posts = JSON.parse(response.body)
        puts "[+] Got #{posts.count} pastes"

        posts.each do |p|
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


while true do
  posts = scraper.scrape(100)
  archive.fetch_and_store(posts)
  sleep 60
end
