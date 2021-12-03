require 'nokogiri'
require 'curb'
require 'csv'

puts "введите ссылка на страницу категории: "
url = gets.chomp
puts "введите имя файла в который будет записан результат: "
@filename = gets

def get_doc(url)
  convert_to_url = URI.parse(url)
  http = Curl.get(convert_to_url)
  doc = Nokogiri::HTML(http.body)
end

def parse_product(url)
  doc = get_doc(url)
  products = []
  doc.xpath('//*[@class = "attribute_radio_list pundaline-variations"]/*' ).each do |row|
    product_price = row.search('span.price_comb').text.strip
    product_image = row.at_xpath('//img[@id="bigpic"]/@src').text.strip
    product_full_name = row.at_xpath('//h1[@class="product_main_name"]').text.strip + "\n" + row.search('span.radio_label').text.strip
    products.push( name: product_full_name, price: product_price, image: product_image )
  end
  products
end

def save_to_csv(products)
  column_header = [ "Name", "Price", "Image" ]
  CSV.open(@filename,"a+" ,force_quotes:true ) do |file|
    file << column_header if file.count.eql? 0
    products.each do |product|
      file << product.values
      puts product.to_s
    end
  end
end

def count_products_in_one_page(doc)
  count_of_products = 0
  doc.xpath('//div[@class = "product-container"]').each do |row|
    count_of_products += 1
  end
  count_of_products
end

def get_and_save_products(doc)
  count_of_products = count_products_in_one_page(doc)
  products = []
  all_urls = doc.xpath("//div[@class='product-desc display_sd']/a/@href").first(count_of_products)
  all_urls.each do |url|
    products += parse_product(url.text)
  end
  save_to_csv(products)
end

def parse_by_url(count_of_pages, url)
  doc = get_doc(url)
  get_and_save_products(doc) #for first page
  (2..count_of_pages).each do |i| #for another pages
    doc = get_doc(url + "?p=#{i}")
    get_and_save_products(doc)
  end
end

def get_all_pages(url)
  puts "идет запись на файл..."
  doc = get_doc(url)
  count_of_pages = doc.xpath("//ul[contains(@class, 'pagination')]/li[position() = (last() - 1)]/a/span/text()").text.to_i
  parse_by_url(count_of_pages, url)
  puts "записано!!"
end

get_all_pages(url)