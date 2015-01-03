require 'mechanize'

m = Mechanize.new
@log = QueueToArrayWriter.new
m.log = Logger.new(@log)


append_raw(@header)
append_raw <<END
<div class="container">
  <div id="hipsterTopBar">
    <h1>Transmitting Fax</h1>
  </div>
  <p>
END
@footer = '</p></div>' + @footer


a('Loading landing page ') #############################################
page = m.get('https://faxout.pdf24.org/')
success

a('Rendering fax-order.pdf ') ##########################################
fax = nil
begin
  fax = render(file: '/basket/fax.pdf')
rescue => e
  append_exception(e)
end

if fax.nil?
  a('✗ – Could not render PDF properly. Please contact the admin.')
  return exit
end
n('✓')


a('Uploading PDF ') ####################################################
page = page.form_with(name: 'uploadForm') do |upload_form|
  field = upload_form.file_uploads.first
  field.mime_type = 'application/pdf'
  field.file_name = @basket.fax_filename
  field.file_data = fax
end.submit

faxid = page.uri.query.match(/faxId=([0-9]+)/)[1] rescue nil
return fail('Could not retrieve fax id from URL.') if faxid.nil?
success


a('Logging In 1/2 ') ###################################################
mail = u @fax_config['pdf24_mail']
pass = u @fax_config['pdf24_pass']
# XXX: different subdomain!
login = m.get("https://fax.pdf24.org/ajax.php?action=logIn&email=#{mail}&password=#{pass}")

json = json_or_fail(login.body)
return if json.nil?

token = json['data']['token'] rescue nil
return fail('Could not retrieve session token.') if token.nil?
success


a('Logging In 2/2 ') ###################################################
setuser = m.get("https://faxout.pdf24.org/client.php?action=setUser&token=#{token}")
json_or_fail(setuser.body)
return if json.nil?
success


a('Adding Fax Number ') ################################################
a(" (#{@basket.shop_fax}) ")
faxnum = u @basket.shop_fax

addfax = m.get("https://faxout.pdf24.org/client.php?action=setTargetNumbers&faxId=#{faxid}&targetNumbers=#{faxnum}")

json = json_or_fail(addfax.body)
return if json.nil?
number_cnt = json['data']['targetNumberCount'] rescue -1
return fail('Expected to have exactly one fax number, but got ' + number_cnt) if number_cnt != 1
success


a('Queuing Fax With PDF24 ') ###########################################
if Rails.env.production?
  send = m.get("https://faxout.pdf24.org/client.php?action=sendFax&faxId=#{faxid}&forceAgainCode=")
  json = json_or_fail(send.body)
  return if json.nil?
else
  a(' SKIPPED because not in production. ')
end
success

n
append_raw <<END
    <div class="alert alert-info">
    It appears the fax has been queued successfully. You should receive a mail from PDF24 at #{h @fax_config['pdf24_mail']} shortly. It will tell you if the fax has been transmitted successfully.
    </div>
    #{basket_link}
END
# FIXME: set address from fax.yml data

@basket.update_attribute(:sha_address, contact_sha_address)

append_raw(@footer)
