## --- BEGIN LICENSE BLOCK ---
# Copyright (c) 2018-present WeWantToKnow AS
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
## --- END LICENSE BLOCK ---

require 'webmock/rspec'

describe Freshsales::Client do
  def freshsales_fixture(path)
    File.read("spec/freshsales/fixtures/#{path}")
  end

  def config(opts = {})
    args = { freshsales_domain: "example", freshsales_apikey: "MYSECRETKEY" }.merge(opts)
    return Freshsales::API.new(args)
  end

  describe "making requests" do
    it "GETs raw_data responses" do
      config = config(raw_data: true)
      subject = Freshsales::Client.new(config)

      raw_data = freshsales_fixture("leads_100.json")

      stub_request(:get, "https://example.freshsales.io/api/leads/100")
        .with(headers: { Authorization: 'Token token=MYSECRETKEY' })
        .to_return(status: 200, body: raw_data, headers: {})

      expected_response = Freshsales::Response.new(headers: {}, body: raw_data)
      response = subject.httprequest("get", "/api/leads/100")
      expect(response.headers).to eq(expected_response.headers)
      expect(response.body).to eq(expected_response.body)
    end

    it "GETs hashes with symbolized keys"
    it "GETs hashes with non symbolized keys"

    it "POSTs string body"
    it "POSTs Hash body"

    it "PUTs string body"
    it "PUTs Hash body"

    it "DELETEs"

    it "converts errors"
  end
end
