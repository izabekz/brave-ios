/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import SDWebImage
import Deferred
import class Data.FaviconMO

class FaviconHandler {
    static let MaximumFaviconSize = 1 * 1024 * 1024 // 1 MiB file size limit

    private var tabObservers: TabObservers!
    private let backgroundQueue = OperationQueue()

    init() {
        self.tabObservers = registerFor(.didLoadPageMetadata, queue: backgroundQueue)
    }

    deinit {
        unregister(tabObservers)
    }

    func loadFaviconURL(_ faviconURL: String, forTab tab: Tab) -> Deferred<Maybe<(Favicon, Data?)>> {
        guard let iconURL = URL(string: faviconURL), let currentURL = tab.url else {
            return deferMaybe(FaviconError())
        }

        let deferred = Deferred<Maybe<(Favicon, Data?)>>()

        var imageOperation: SDWebImageOperation?

        let webImageCache = WebImageCacheManager.shared

        let onProgress: ImageCacheProgress = { receivedSize, expectedSize, _ in
            if receivedSize >= FaviconHandler.MaximumFaviconSize || expectedSize > FaviconHandler.MaximumFaviconSize {
                imageOperation?.cancel()
            }
        }

        let onSuccess: (Favicon, Data?) -> Void = { [weak tab] (favicon, data) -> Void in
            defer { deferred.fill(Maybe(success: (favicon, data))) }
            
            guard let tab = tab else { return }
            
            tab.favicons.append(favicon)
            if !tab.isPrivate {
                FaviconMO.add(favicon, forSiteUrl: currentURL)
                
            }
        }

        let onCompletedSiteFavicon: ImageCacheCompletion = { image, data, _, _, url in
            let favicon = Favicon(url: url.absoluteString, date: Date())

            guard let image = image else {
                favicon.width = 0
                favicon.height = 0

                onSuccess(favicon, data)
                return
            }

            favicon.width = Int(image.size.width)
            favicon.height = Int(image.size.height)

            onSuccess(favicon, data)
        }

        let onCompletedPageFavicon: ImageCacheCompletion = { image, data, _, _, url in
            guard let image = image else {
                // If we failed to download a page-level icon, try getting the domain-level icon
                // instead before ultimately failing.
                let siteIconURL = currentURL.domainURL().appendingPathComponent("favicon.ico")
                imageOperation = webImageCache.load(from: siteIconURL, options: [.lowPriority], progress: onProgress, completion: onCompletedSiteFavicon)

                return
            }

            let favicon = Favicon(url: url.absoluteString, date: Date())
            favicon.width = Int(image.size.width)
            favicon.height = Int(image.size.height)

            onSuccess(favicon, data)
        }

        imageOperation = webImageCache.load(from: iconURL, options: [.lowPriority], progress: onProgress, completion: onCompletedPageFavicon)

        return deferred
    }
}

extension FaviconHandler: TabEventHandler {
    func tab(_ tab: Tab, didLoadPageMetadata metadata: PageMetadata) {
        tab.favicons.removeAll(keepingCapacity: false)
        guard let faviconURL = metadata.faviconURL else {
            return
        }

        loadFaviconURL(faviconURL, forTab: tab) >>== { (favicon, data) in
            TabEvent.post(.didLoadFavicon(favicon, with: data), for: tab)
        }
    }
}

class FaviconError: MaybeErrorType {
    internal var description: String {
        return "No Image Loaded"
    }
}
