desc 'CLI .well-known/host-meta request'
task :host_meta, :file  do |t, args|

  require 'erb'
  require 'rack/utils'

  path = 'app/views/publics/host_meta.erb'
  ::File.open(path) do |file|
    template = file.read( file.stat.size)
    begin
      outfile = ::File.open( args[:file], "w" )
    rescue
      outfile = $stdout
    end
    outfile.puts(  ERB.new( template, 0, "%<>").result)
    outfile.close unless outfile == $stdout
  end

end

