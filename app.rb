require 'sinatra'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'

class App < Sinatra::Base
  get '/' do
    "Hello World"
  end
end