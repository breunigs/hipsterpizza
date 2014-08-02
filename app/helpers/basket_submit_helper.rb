# encoding: utf-8

module BasketSubmitHelper
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
    l = @log.get.map { |x| x.join[0..200].strip }

    html_safe = l.map { |x| h(x) }.join("\n")
    append_raw(%(<!--\n#{html_safe}\n-->\n))

    Rails.logger.info '==='*15 << '  FAX LOGGING FOLLOWS ' << '==='*15
    l.each { |x| Rails.logger.info "FAX: #{x}"}
    Rails.logger.info '---'*15 << '   FAX LOGGING ENDED  ' << '---'*15
  end

  def success
    a('✓')
    log
    n
  end

  def fail(msg)
    n('✗')
    append_raw('<div class="alert alert-danger">')
    n(msg + '. See this page’s source code for detailed logs.')
    log
    append_raw('</div>')
    append_raw basket_link
    exit
  end

  def basket_link
    %(<a href="#{basket_path(@basket)}" class="btn btn-default">Return To Basket</a>)
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
end
