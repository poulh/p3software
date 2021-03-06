//
//  MediaDirectoryHelper.swift
//  P3Software
//
//  Created by Poul Hornsleth on 11/16/17.
//  Copyright © 2017 Poul Hornsleth. All rights reserved.
//

import Cocoa

class MediaDirectoryHelper : NSObject
{
    struct MediaDirectoryInfo
    {
        init( actualURL: URL, displayURL: URL )
        {
            self.actualURL = actualURL
            self.displayURL = displayURL
        }
        var actualURL : URL
        var displayURL : URL
    }
    
    func getMediaDirectoryURL( displayDirectoryURL: URL?, mediaDirectoryName: String ) -> MediaDirectoryInfo?
    {
        //let helper = MediaDirectoryHelper()
        if let url = displayDirectoryURL
        {
            if let actualURL = self.getActualURL( fromDisplayURL: url )
            {
                return MediaDirectoryInfo( actualURL: actualURL, displayURL: url )
            }
        }
        
        var rval : MediaDirectoryInfo? = nil
        self.displayOpenPanel( title: "Please Select Media Directory") { (chosenURL: URL?) in
            if var url = chosenURL
            {
                if( url.pathComponents.last != mediaDirectoryName )
                {
                    url.appendPathComponent(mediaDirectoryName)
                }
                let displayURL = self.getDisplayURL(url: url)
                rval = MediaDirectoryInfo( actualURL: url, displayURL: displayURL )
            }
        }
        
        return rval
    }
    
    func getActualURL( fromDisplayURL: URL ) -> URL?
    {
        if( self.directoryExists(url: fromDisplayURL ) )
        {
            //most of the time this will be the case
            return fromDisplayURL
        }
        
        if( self.isDirectoryOnMountedVolume( url: fromDisplayURL ) )
        {
            if let volumeBaseURL = self.volumeBaseURL( url: fromDisplayURL )
            {
                let volumeDisplayName = volumeBaseURL.lastPathComponent
                let keys = [URLResourceKey.volumeNameKey, URLResourceKey.volumeIsRemovableKey, URLResourceKey.volumeIsEjectableKey]
                if let mountedVolumeURLs = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: FileManager.VolumeEnumerationOptions.produceFileReferenceURLs)
                {
                    for mountedVolumeURL in mountedVolumeURLs
                    {
                        let mountedVolumeDisplayName = fileManager.displayName( atPath: mountedVolumeURL.relativePath )
                        if( mountedVolumeDisplayName == volumeDisplayName )
                        {
                            let components = fromDisplayURL.pathComponents
                            var volumeURL = mountedVolumeURL
                            let volumeBaseComponents = volumeBaseURL.pathComponents
                            for i in volumeBaseComponents.count ..< components.count
                            {
                                volumeURL = volumeURL.appendingPathComponent(components[i])
                            }
                            return volumeURL
                        }
                    }
                }
            }
        }
        return nil
    }
    
    func getDisplayURL( url: URL ) -> URL
    {
        if( !self.isDirectoryOnMountedVolume( url: url ) )
        {
            return url
        }
        
        if let volumeBaseURL = self.volumeBaseURL( url: url )
        {
            let volumeDisplayName = self.fileManager.displayName(atPath: volumeBaseURL.relativePath)

            var components = url.pathComponents
            let volumeBaseComponents = volumeBaseURL.pathComponents
            
            components[ volumeBaseComponents.count - 1 ] = volumeDisplayName
            
            var rval = URL( fileURLWithPath: components[0] )

            for i in 1 ..< components.count
            {
                rval = rval.appendingPathComponent(components[i])
            }
            return rval
        }
        
        return url
    }
    
    private func directoryExists( url: URL ) -> Bool
    {
        var isDir : ObjCBool = false
        if( fileManager.fileExists(atPath: url.relativePath, isDirectory: &isDir) )
        {
            if( isDir.boolValue )
            {
                return true
            }
            else
            {
                print("problem: there is a file in the spot where the dir should be")
            }
        }
        return false
    }
    
    
    
    private func isDirectoryOnMountedVolume( url: URL ) -> Bool
    {
        if( url.relativePath.range(of:"/Volumes") != nil )
        {
            return url.pathComponents.count >= 3
        }
        return false
    }
    
    private func volumeBaseURL( url: URL ) -> URL?
    {
        if( !isDirectoryOnMountedVolume( url: url ) )
        {
            return nil
        }
        
        let components = url.pathComponents
        if( components.count < 3 )
        {
            //not enough info in path
            return nil
        }

        var u = URL(fileURLWithPath: components[0])
        u = u.appendingPathComponent(components[1]).appendingPathComponent(components[2])

        return u
    }
    
    
    private func displayOpenPanel( title: String, callback:@escaping (URL?)-> () )
    {
        let panel = NSOpenPanel()
        
        panel.title                   = title
        panel.showsResizeIndicator    = true
        panel.showsHiddenFiles        = false
        panel.canChooseDirectories    = true
        panel.canChooseFiles          = false
        panel.canCreateDirectories    = true
        panel.allowsMultipleSelection = false
        
        
        //        if let win = window
        //        {
        //            print( "begin sheet")
        //            panel.beginSheet( win, completionHandler: { (response:NSModalResponse) in
        //
        //            })
        //        }
        //        else
        // {

        if( panel.runModal() != NSApplication.ModalResponse.OK )
        {
            
        }
        //}
        
        if let url = panel.url
        {
            callback( url )
            return
        }
        callback( nil )
        return
    }


    private let fileManager = FileManager()

}
