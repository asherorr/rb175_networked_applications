require "sinatra"
require "sinatra/reloader"
require "tilt/erubi"

before do
  @contents = File.readlines("data/toc.txt")
end

get "/" do
  @title = "Sherlock Homes"

  erb :home
end

get "/chapters/:number" do
  chapter_number = params[:number]
  chapter_name = @contents[chapter_number.to_i - 1]
  @title = "Chapter #{chapter_number}, #{chapter_name}"
  
  @chapter = File.read("data/chp#{chapter_number}.txt")

  erb :chapter
end

get "/show/:name" do
  params[:name]
end

get "/search" do
  @results = chapters_matching(params[:query])
  erb :search
end

not_found do
  redirect "/"
end

helpers do
   def highlight(text, query)
    text.gsub(query, %(<strong>#{query}</strong>))
   end

  def in_paragraphs(chapter)
    counter = 0
    chapter.split("\n\n").each_with_index.map do |paragraph, idx|
      "<p id=#{idx + 1}>#{paragraph}</p>" 
    end.join
  end
end

def each_chapter
  @contents.each_with_index do |name, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, name, contents
  end
end

def chapters_matching(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |number, name, contents|
    results << {number: number, name: name, contents: contents} if contents.include?(query)
  end

  results
end

def paragraphs_matching(matching_chapter, query)
  paragraphs = matching_chapter.split("\n\n").map.with_index(1) { |para, idx| [idx, para] }
  paragraphs.select { |_id, text| text.include?(query) }
end
