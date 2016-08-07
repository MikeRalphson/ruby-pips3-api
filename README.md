PIPs3 Ruby API
==============

An ActiveResource style wrapper for the PIPs3 API.


Example usage
-------------

```ruby
require "pips3-api"
require "pp"

Pips3Api::Base.config = {
  :endpoint => "https://api.test.bbc.co.uk/pips/api/v1",
  :certificate_path => ENV["HTTPS_CERT_FILE"],
  :proxy => ENV["HTTP_PROXY"],
}

# Find as segment using its VCS item key
segment = Pips3Api::Segment.find('6B668360C2FD11E276E93C4A92EC9E7C01011008', :identifier_type => 'item_key')
pp segment

segment = Pips3Api::Segment.find('3e4be9fb893c11da91960002a543bf45', :identifier_type => 'item_key')
pp segment

# segment.release_title = ''
# segment.record_label = Time.now.to_s
# segment.track_number = nil
# segment.save!
```

