# Freshsales

[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/DragonBox/freshsales/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/freshsales.svg?style=flat)](https://rubygems.org/gems/freshsales)
[![Build Status](https://img.shields.io/circleci/project/DragonBox/freshsales/master.svg?style=flat)](https://circleci.com/gh/DragonBox/freshsales)
[![Coverage Status](https://coveralls.io/repos/github/DragonBox/freshsales/badge.svg?branch=master)](https://coveralls.io/github/DragonBox/freshsales?branch=master)

Freshsales is a ruby wrapper around [Freshsales API](https://www.freshsales.io/api/)

---

## Installation

```shell
gem install freshsales
```

### Requirements

A Freshsales account and an API key. You can set your API key here.

https://yourdomain.freshsales.io/personal-settings/api-settings

## Getting started

```ruby
# given https://yourdomain.freshsales.io/ and your API key
freshsales = Freshsales::API.new(freshsales_domain: "yourdomain", freshsales_apikey: "...")
```

### Design philosophy

Freshsales expose resources using a RESTful API allowing to [CRUD](https://en.wikipedia.org/wiki/Create,_read,_update_and_delete) those resources. It also provides extra features such as search.

Inspired by [gibbon](https://github.com/amro/gibbon), this library provides a simple dynamic language to construct the URLs required to query those resources.

E.g. `freshsales.leads.post(body: requestbody)` would represent a `POST /api/leads/` request and return a `Freshsale::Response` instance.

The json data (`requestbody`) can be passed as string or Hashes.

The received json data can be obtained as raw or Hashes (with symbolized keys or not).

## Examples

### Create / Read / Update / Search / Delete resources

```ruby
email = "sample@sample.com"

lead_data = %({"lead":{"last_name":"Sampleton (sample)", "email": "#{email}"}})

# Create lead
result = freshsales.leads.post(body: lead_data)
lead_id = result.body['lead']['id']

updated_lead_data = %({"lead":{"mobile_number":"1-926-555-9999", "email": "#{email}"}})

# Read the lead
freshsales.leads(lead_id).get.body

# Update the lead
freshsales.leads(lead_id).put(body: updated_lead_data).body

# Search the lead by email
sample = freshsales.search.get(params: {include: "lead", q: email}).body.first

# Delete it
freshsales.leads(lead_id).delete
```

### Finding a particular view

```ruby
filters = freshsales.contacts.filters.get

view_id = filters.body['filters'].select{|f| "All Contacts" == f['name'] }.first['id']
```

### Paginated resources

Some resources are paginated and controlled by the `per_page` and `page` parameters.

While you can return individual pages like this:
```ruby
freshsales.contacts.view(view_id).get(params: {"per_page": 100, "page": 2})).body
```

the library also allows to iterate over all pages either one element at a time or one page at a time, lazily making the requests for the different pages when required by the client.

```ruby
freshsales.contacts.view(view_id).get_all.each do |contact|
  # do something with this contact, which may come from any page
end

page_params = { "per_page": 100, "sort": "id", "sort_type": "asc", "include": "owner,creater,source"}
freshsales.contacts.view(view_id).get_all_pages(params: page_params).each do |contact_page|
  # do something with this page's data which may contain up to 100 contacts and
  # their associated owner, creater and source data
end
```

`get_all` and `get_all_pages` return a `Freshsale::Cursor` whose `each` method returns a ruby `Enumerator` when no block is given.

**tip** Enumerators in ruby can be used as [Enumerable](https://ruby-doc.org/core/Enumerable.html). This allows you to apply collection operations on them, even chain them, to transform or filter the returned data.

E.g. if you wanted to restrict the number of elements/pages you could do `get_all[_pages].each.take(100)[.each]`.

### Troubleshoot

Enable the `debug` option (`Freshsales::API.new(debug: true)`)

### WIP / first public release

The library is a work in progress. There will be a couple of API changes before the first public version is officially rolled out. Check [the issues targeted for the 0.1.0 milestone](https://github.com/DragonBox/freshsales/issues?q=is%3Aopen+is%3Aissue+milestone%3A0.1.0)

### Solve SSL Errors

If you face an issue similar to this one

```shell
SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed
```
your ruby setup to work with OpenSSL probably needs to be fixed.

 * __On MacOS:__

Your version of OpenSSL may be be outdated, make sure you are using the last one.

 * __On Windows:__

A fix to the issue stated above has been found on [StackOverflow](http://stackoverflow.com/questions/5720484/how-to-solve-certificate-verify-failed-on-windows). If you follow the steps described in this topic, you will most likely get rid of this issue.
