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

## Getting started

```ruby
# given https://yourdomain.freshsales.io/ and your token
freshsales = Freshsales::API.new(freshsales_token: "...", freshsales_domain: "yourdomain")
```

## Examples

* Create / Update / Get / Delete

```ruby
email = "sample@sample.com"

lead_data = %({"lead":{"last_name":"Sampleton (sample)", "email": "#{email}"}})

# create lead
result = freshsales.leads.post(body: lead_data)
lead_id = result.body['lead']['id']

updated_lead_data = %({"lead":{"mobile_number":"1-926-555-9999", "email": "#{email}"}})

# update the lead
freshsales.leads(lead_id).put(body: updated_lead_data).body

# get the lead
freshsales.leads(lead_id).get.body

# search the lead by email
sample = freshsales.search.get(params: {include: "lead", q: email}).body.first

# delete it
freshsales.leads(lead_id).delete
```

### Troubleshoot

Enable the `debug` option

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
