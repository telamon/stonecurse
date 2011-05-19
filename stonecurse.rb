class Stonecurse
  require 'nokogiri'
  require 'curb'
  require 'base64'
  require 'open-uri'
  attr_accessor :mime,:location,:ng
  def Stonecurse::petrify(url,*args)
    ng=Stonecurse.new(url).petrify    
    if args.first
      open(args.first,'w') do |f|
        f.write(ng)
      end
      puts "Saved to file: #{args.first}"
      nil
    else
      ng
    end
  end
  def initialize(url)
    @url = url    
  end
  def petrify
    html,@mime,@location = read_url(@url)
    @location||=@url
    if @url != @location
      log "Redirected to: #{@location}"
    end
    @ng = Nokogiri::HTML.parse(html)
    
    #Identify resources
    @images= @ng.xpath '//img'
    @stylesheets = @ng.xpath '//link[@rel="stylesheet"]'
    @scripts= @ng.xpath('//script[@src]')
    
    
    #Embed stylesheets
    log "Embedding #{@stylesheets.count} stylesheets"
    @stylesheets.each do|style|      
      tag =  Nokogiri::XML::Element.new('style',@ng)  
      tag.add_child Nokogiri::XML::CDATA.new(@ng, read_url(relative_url(style['href'])).first)
      style.add_next_sibling tag
      tag['media']= style['media'] if style['media']
      tag['type']= style['type'] if style['type']
      tag['rel']='stylesheet'
      style.remove
    end
    #Embed scripts
    log "Embedding #{@scripts.count} scripts"
    @scripts.each do |s|
      s.add_child Nokogiri::XML::CDATA.new(@ng,read_url(relative_url(s['src'])).first)
      s.attribute('src').remove
    end
    #Embed images
    
    log "Embedding #{@images.count} images"
    @images.each{|image|
      break if image.nil? || image['src'].nil?
      log "Embedding image: #{image['src']}"
      gfx = read_url relative_url(image['src'])
      image['src']="data:#{gfx[1]};base64,"+Base64.encode64(gfx[0])
      #log image.to_s
    }
    @ng.to_s
  end
  
  private 
  Debug=true
  def log(str)
    puts str.to_s if Debug
  end
  def relative_url(url)    
    if url.match(/^http:\/\//)
      url
    else
      url=url.split('?')       
      url[0] = URI::join(@location , url[0])
      url.join('?')
    end
  end
    
  def read_url(url)
    Stonecurse::read_url(url)
  end
  def Stonecurse::read_url(url)
    puts "Fetching: #{url.to_s}" if Debug
    r=Curl::Easy.http_get(url.to_s) do |easy|
      easy.follow_location = true
    end
    loc=nil
    if r.header_str.match(/Location\s*:\s*(.*)$/)
      loc= $1.gsub("\r",'')      
    end    
    [r.body_str, r.content_type, loc ]    
  end
end