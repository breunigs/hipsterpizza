def a(text) # append
  @stream.write(h text.to_s) unless @stream.closed?
end

def n(text = '') # new line
  @stream.write("#{h text.to_s}<br>\n") unless @stream.closed?
end

def append_raw(text)
  @stream.write(text.to_s) unless @stream.closed?
end

def log
  l = @log.get.map { |x| h(x.join[0..200].strip) }
  append_raw(%|<!--\n#{l.join("\n")}\n-->\n|)
end

def success
  a('✓')
  log
  n
end

def fail(msg)
  n('✗ – ' + msg + '. See this page’s source code for detailed logs.')
  log
  append_raw basket_link
  exit
end

def basket_link
  %|<a href="#{basket_with_uid_path(@basket.uid)}" class="button">Return To Basket</a>|
end

def json_or_fail(raw)
  @log.write('Received JSON: ' + raw)

  begin
    json = JSON.parse(raw)
  rescue => e
    fail('JSON parser failed on response: ' + e.message)
    return nil
  end

  if json['success'] != true
    err = json['error'] || nil
    err = "Message: #{err['code']} #{err['message']}" if err
    fail("PDF24 reported a failure. #{err}")
    return nil
  end

  json
end

def exit
  append_raw(@footer)
  @stream.close
end



m = Mechanize.new
@log = QueueToArrayWriter.new
m.log = Logger.new(@log)


append_raw(@header)
append_raw <<END
  <div id="hipsterTopBar">
    <h1>Transmitting Fax</h1>
  </div>
  <p>
END
@footer = '</p>' + @footer


a('Loading landing page ') #############################################
page = m.get('https://faxout.pdf24.org/')
success

a('Rendering fax-order.pdf ') ##########################################
fax = render(file: '/basket/fax.pdf') rescue nil
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
mail = u @cfg['pdf24_mail']
pass = u @cfg['pdf24_pass']
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
faxnum = u @basket.fax_number
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
    <br><br>
    It appears the fax has been queued successfully. You should receive a mail from PDF24 at #{h @cfg['pdf24_mail']} shortly. It will tell you if the fax has been transmitted successfully.
    <br><br>
    #{basket_link}
END
# FIXME: set address from fax.yml data

cookie_set(:action, :mark_delivery_arrived)
@basket.update_column(:sha_address, contact_sha_address)

append_raw(footer)
