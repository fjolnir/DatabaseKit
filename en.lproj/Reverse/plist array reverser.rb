require 'osx/cocoa'
include OSX

inPath = "/Users/aptiva/Desktop/ActiveRecord/English.lproj/irregulars.plist"
outPath = "/Users/aptiva/Desktop/ActiveRecord/English.lproj/reverse irregulars.plist"
original = NSArray.arrayWithContentsOfFile inPath
reverseEnum = original.reverseObjectEnumerator

reversed = NSMutableArray.array
while obj = reverseEnum.nextObject
  reversed.addObject obj
end
reversed.writeToFile_atomically outPath, true