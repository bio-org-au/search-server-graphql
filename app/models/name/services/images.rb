# frozen_string_literal: true

#   Copyright 2015 Australian National Botanic Gardens
#
#   This file is part of the NSL Editor.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

#  Request all APII metadata and cache it
#
#  Currently not using a queue or separate thread.
class Name::Services::Images
  def self.load
    info('start load')
    the_response = request_the_data
    cache_the_data(the_response)
    info('image data cache refreshed')
  rescue StandardError => e
    # Do not let this interrupt normal processing
    error("Problem loading image data: #{e}")
  end

  def self.request_the_data
    url = Rails.configuration.image_data_url
    RestClient.get(url, accept: :csv)
  end

  def self.cache_the_data(response)
    if response.code == 200
      Rails.cache.write 'images',
                        hash_the_data(response),
                        expires_in: expiry_period
    else
      error("Unsuccessful request: #{response.code}")
    end
  end

  def self.hash_the_data(response)
    hash = {}
    response.each_line do |line|
      fields = line.split(',')
      hash[fields[0].to_s.tr_s('"', '')] =
        ((fields[1].to_s || '\n').tr_s('"', '').chomp.to_i || 0)
    end
    hash
  end

  def self.expiry_period
    Rails.configuration.try('image_cache_expiry_period') || 24.hours
  end

  def self.info(s)
    Rails.logger.info("Name::Services::Images #{s}")
  end

  def self.error(s)
    Rails.logger.error("Name::Services::Images error: #{s}")
  end
end
