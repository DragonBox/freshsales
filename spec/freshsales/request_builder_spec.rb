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

describe Freshsales::RequestBuilder do
  describe "missing methods" do
    it "respond to .method call on instance" do
      subject = Freshsales::RequestBuilder.new(nil)
      expect(subject.method(:accounts)).to be_a(Method)
    end
  end
  describe "path" do
    it "combines methods into path parts" do
      client = double(Freshsales::Client)
      expect(client).to receive(:httprequest).with("get", "/api/leads/100/convert")
      subject = Freshsales::RequestBuilder.new(client)
      subject.leads(100).convert.get
    end
  end
end
