# frozen_string_literal: true

# Disable ZIP64 extensions when writing zip archives.
#
# rubyzip 3.x defensively emits ZIP64 extended-information extra fields for
# every streamed entry (because it doesn't know the size upfront), which
# sets the classic 32-bit size fields to 0xFFFFFFFF and stashes the real
# sizes in the extra. Our DragonRuby client's pure-Ruby ZipReader only
# understands classic 32-bit headers; all Forge package archives and the
# base library zip are < 4 GB, so ZIP64 provides no benefit.
require "zip"
Zip.write_zip64_support = false
