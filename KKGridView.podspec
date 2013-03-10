Pod::Spec.new do |s|
  s.name     = 'KKGridView'
  s.version  = '0.6.8.2'
  s.license  = 'MIT'
  s.platform = :ios
  s.summary  = 'Gridview for iOS.'
  s.homepage = 'https://github.com/kolinkrewinkel/KKGridView'
  s.authors  = { 'Kolin Krewinkel'   => 'kolin@kolinkrewinkel.com',
                 'Giulio Petek'      => 'gi-lo@touch-mania.com',
                 'Jonathan Sterling' => 'jonsterling@me.com',
                 'Kyle Hickinson'    => 'kyle.hickinson@gmail.com',
                 'Matthias Tretter'  => 'matthias.tretter@gmail.com',
                 'Peter Steinberger' => 'me@petersteinberger.com' }

  s.source   = { :git => 'https://github.com/xzeror/KKGridView.git', :commit => 'f98073114c7deeea825411b2a2f2380b8b069f36' }

  s.source_files = 'KKGridView'
  s.clean_paths  = 'Examples', 'KKGridView.xcodeproj', 'Resources'
  s.library      = 'stdc++'
  s.framework    = 'QuartzCore'
  s.requires_arc = true
end
