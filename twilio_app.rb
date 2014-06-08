require 'sinatra'
require 'json'
require 'active_support/core_ext/hash/indifferent_access'

class TwilioApp < Sinatra::Base 
  post '/send_sms' do
    content_type :json
    payload = JSON.parse(request.body.read).with_indifferent_access
    request_id = payload[:request_id]
    sms = payload[:sms]
    params = payload[:parameters]

    begin
      client = Twilio::REST::Client.new(params[:account_sid], params[:auth_token])
      client.account.messages.create(
        :from => sms[:from],
        :to => sms[:phone],
        :body => sms[:message])
    rescue => e
      # tell the hub about the unsuccessful delivery attempt
      status 500
      return { request_id: request_id, summary: "Unable to send SMS message. Error: #{e.message}" }.to_json + "\n"
    end

    # acknowledge the successful delivery of the message
    { request_id: request_id, summary: "SMS message sent" }.to_json + "\n"
  end
  
   # This is needed to get shipments & tracking numbers for the store (CCODE)
   post '/get_shipments' do

    begin
      # authenticate_shipstation

      # Shipstation doesn't record time information - just date, so round the parameter down
      since = Time.parse(@config[:since]).utc.beginning_of_day.iso8601

      @client.Shipments.filter("ModifyDate ge datetime'#{since}' and ShipDate ne null")
      panda_result = @client.execute

      # TODO - get shipping carrier, etc.
      panda_result.each do |resource|
        add_object :shipment, {
          id: resource.ShipmentID.to_s,
          tracking: resource.TrackingNumber,
          order_id: resource.OrderID.to_s
        }
      end
      @kount = panda_result.count

      # return current timestamp so parameter updates on hub side
      # NOTE: shipstation doesn't provide detail beyond date so we need to round it down in order
      # to not miss any shipments
      add_parameter 'since', Time.now.utc.beginning_of_day
    rescue => e
      # tell Honeybadger
      # log_exception(e)

      # tell the hub about the unsuccessful get attempt
      result 500, "Unable to get shipments. Error: #{e.message}"
    end

    result 200, "Retrieved #{@kount} shipments"
  end

end