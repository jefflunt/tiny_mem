# a tiny memory measurement tool for linux and macos, measuring resident set
# size (rss) (i.e. total memory allocated and still in use).
#
# ex:
#   mem = TinyMem.new
#   mem.measure 'array_alloc' do
#     Array.new(100_000) { 'hello' }
#   end
#
#   mem.measure 'nothing'
#
#   pp mem.stats
# ```
#
# this would output something like:
#
#   [
#     ["array_alloc", 70568,  72732, 2164   ],
#     ["nothing",     72744,  72744, 0      ]
#   ]  ^label         ^before ^after ^change ... in kilobytes
class TinyMem
  attr_reader :stats

  def initialize
    @stats = []
  end

  def measure(label)
    pid = Process.pid
    before = _mem
    yield if block_given?
    after = _mem

    @stats << [label, before, after, after-before]
  end

  def _mem
    case RUBY_PLATFORM
    when /linux/
      begin
        line = File.read("/proc/#{Process.pid}/status").match(/VmRSS:\s+(\d+)\s*/)
        line ? line[1].to_i : 'unknown'
      rescue Errno::ENOENT
        'error'
      end
    when /darwin/
      `ps -o rss= -p #{Process.pid}`.to_i
    else
      "#{RUBY_PLATFORM} not supported"
    end
  end
end
