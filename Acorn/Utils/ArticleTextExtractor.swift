//
//  ArticleTextExtractor.swift
//  Acorn
//
//  Created by macOS on 16/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import SwiftSoup

class ArticleTextExtractor {
    let TAG = "TextExtractor"
    
    // Interesting nodes
    let NODES = try? NSRegularExpression(pattern:"p|div|td|h1|h2|article|section|span", options: .caseInsensitive)
    
    // Unlikely candidates
    let UNLIKELY = try? NSRegularExpression(pattern:"com(bx|ment|munity)|dis(qus|cuss)|e(xtra|[-]?mail)|foot|header|menu|re(mark|ply)|rss|sh(are|outbox)|social|twitter|facebook|pinterest|sponsor|a(d|ll|gegate|rchive|ttachment)|(pag(er|ination))|popup|print|login|si(debar|gn|ngle)|hinweis|expla(in|nation)?|metablock", options: .caseInsensitive)
    
    // Most likely positive candidates
    let POSITIVE = try? NSRegularExpression(pattern:"(^(body|content|h?entry|cb-(entry-itemprop)|main|page|post|text|blog|story|haupt))|arti(cle|kel)|instapaper_body", options: .caseInsensitive)
    
    // Very most likely positive candidates, used by Joomla CMS
    let ITSJOOMLA = try? NSRegularExpression(pattern:"articleBody", options: .caseInsensitive)
    
    // Most likely negative candidates
    let NEGATIVE = try? NSRegularExpression(pattern:"nav($|igation)|user|com(ment|bx)|(^com-)|contact|"
    + "foot|masthead|(me(dia|ta))|outbrain|promo|related|scroll|(sho(utbox|pping))|"
    + "sidebar|sponsor|tags|tool|widget|player|disclaimer|toc|infobox|vcard|footer|"
    + "mh-loop|mh-excerpt")
    
    let NEGATIVE_STYLE =
    try? NSRegularExpression(pattern:"hidden|display: ?none|font-size: ?small", options: .caseInsensitive)
    
    /**
     * @param input            extracts article text from given html string. wasn't tested
     *                         with improper HTML, although jSoup should be able to handle minor stuff.
     * @return extracted article, all HTML tags stripped
     */
    func extractContent(input: String, selector: String?, baseUrl: String) -> String? {
        do {
            if let content = extractContent(doc: try SwiftSoup.parse(input), selector: selector, baseUrl: baseUrl) {
                return content
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func extractContent(doc: Document?, selector: String?, baseUrl: String) -> String? {
        do {
            if (doc == nil) {
                return nil
            }
        
            // now remove the clutter
            prepareDocument(doc!, baseUrl)
            
            // init elements
            let nodes = getNodes(doc!, selector: selector)
            var maxWeight = 0
            var bestMatchElement: Element?
            
            for entry in nodes! {
                //var currentWeight = 0
//                let html = try entry.outerHtml()
//                if html.contains("content") {
//                    currentWeight = getWeight(entry, true)
//                    print("weight: \(try entry.outerHtml().prefix(20)): \(currentWeight)")
//                } else {
//                    currentWeight = getWeight(entry, false)
//                }
                let currentWeight = getWeight(entry, false)
                
                if (currentWeight > maxWeight) {
                    maxWeight = currentWeight
                    bestMatchElement = entry
                    
                    if (maxWeight > 300) {
                        break
                    }
                }
            }
            
            //print("bestMatchWeight: \(try bestMatchElement?.outerHtml().prefix(20)): \(maxWeight)")
            
            let metas = getMetas(doc!)
            var ogImage: String?
            for entry in metas! {
                let metaProperty = try entry.attr("property")
                if (entry.hasAttr("property") && "og:image" == metaProperty) {
                    ogImage = try entry.attr("content")
                    break
                }
            }
            
            if (bestMatchElement != nil) {
                var ret = try bestMatchElement!.html()
                
                if (ogImage != nil && !ret.contains(ogImage!)) {
                    ret = "<img src=\"\(ogImage!)\"><br>\n"+ret
                }
                return ret
            }
            
            return nil
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    /**
     * @param input            cleans article text from given html string.
     * @return cleaned article, all unwanted HTML tags stripped
     */
    func cleanContent(input: String, baseUrl: String) -> String? {
        do {
            if let content = cleanContent(doc: try SwiftSoup.parse(input), baseUrl: baseUrl) {
                return content
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func cleanContent(doc: Document?, baseUrl: String) -> String? {
        do {
            if (doc == nil) {
                return nil
            }
            
            // now remove the clutter
            prepareDocument(doc!, baseUrl)
            return try doc?.text()
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    /**
     * Weights current element. By matching it with positive candidates and
     * weighting child nodes. Since it's impossible to predict which exactly
     * names, ids or class names will be used in HTML, major role is played by
     * child nodes
     *
     * @param e                Element to weight, along with child nodes
     */
    func getWeight(_ e: Element, _ debugIndicator: Bool) -> Int {
        var weight = calcWeight(e, debugIndicator)
        if debugIndicator { print("textLength: \(e.ownText().count / 10)") }
        weight += e.ownText().count / 10
        weight += weightChildNodes(rootEl: e, debugIndicator)
        return weight
    }
    
    /**
     * Weights a child nodes of given Element. During tests some difficulties
     * were met. For instance, not every single document has nested paragraph
     * tags inside of the major article tag. Sometimes people are adding one
     * more nesting level. So, we're adding 4 points for every 100 symbols
     * contained in tag nested inside of the current weighted element, but only
     * 3 points for every element that's nested 2 levels deep. This way we give
     * more chances to extract the element that has less nested levels,
     * increasing probability of the correct extraction.
     *
     * @param rootEl           Element, who's child nodes will be weighted
     */
    func weightChildNodes(rootEl: Element, _ debugIndicator: Bool) -> Int {
        var weight = 0
        var pEls = [Element]()
        
        do {
            for child in rootEl.children() {
                let text = try child.text()
                let textLength = text.count
                if (textLength < 20) { continue }
        
                let ownText = child.ownText()
                let ownTextLength = ownText.count
                if (ownTextLength > 200) {
                    weight += max(50, ownTextLength / 10)
                    if debugIndicator { print("childTextLength: \(max(50, ownTextLength / 10))") }
                }
            
                if (child.tagName() == "h1" || child.tagName() == "h2") {
                    if debugIndicator { print("\(child.tagName()): h1/h2 +30") }
                    weight += 30
                } else if (child.tagName() == "div" || child.tagName() == "p" || child.tagName() == "span") {
                    weight += calcWeightForChild(ownText, debugIndicator)
                    if (child.tagName() == "p" && textLength > 50) { pEls.append(child) }
                    
                    if try child.className().lowercased() == "caption" {
                        if debugIndicator { print("\(try child.className().lowercased()): caption +30") }
                        weight += 30
                    }
                }
            }
            
            if (pEls.count >= 2) {
                for subEl in rootEl.children() {
                    if "h1;h2;h3;h4;h5;h6".contains(subEl.tagName()) {
                        if debugIndicator { print("\(subEl.tagName()): h1-h6 +20") }
                        weight += 20
                    }
                }
            }
            
            return weight
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return 0
    }
    
    func calcWeightForChild(_ text: String, _ debugIndicator: Bool) -> Int {
        if debugIndicator { print("childWeight: text length \(text.count/25)") }
        return text.count / 25
    }
    
    func calcWeight(_ e: Element, _ debugIndicator: Bool) -> Int {
        var weight = 0
        do {
            if (POSITIVE?.matches(in: try e.className(), options: [], range: NSMakeRange(0, try e.className().count)).count)! > 0 {
                if debugIndicator { print("\(try e.className()) : class positive +35") }
                weight += 35
            }
            
            if (POSITIVE?.matches(in: e.id(), options: [], range: NSMakeRange(0, e.id().count)).count)! > 0 {
                if debugIndicator { print("\(e.id()): id positive +40") }
                weight += 40
            }
            
//            if ITSJOOMLA?.matches(in: e.attr().toString(), options: [], range: NSMakeRange(0, e.attr().toString().count)).count > 0 { weight += 200 }
            
            if (UNLIKELY?.matches(in: try e.className(), options: [], range: NSMakeRange(0, try e.className().count)).count)! > 0 {
                if debugIndicator { print("\(try e.className()): class unlikely -20") }
                weight -= 20
            }
            
            if (UNLIKELY?.matches(in: e.id(), options: [], range: NSMakeRange(0, e.id().count)).count)! > 0 {
                if debugIndicator { print("\(e.id()): id unlikely -20") }
                weight -= 20
            }
            
            if (NEGATIVE?.matches(in: try e.className(), options: [], range: NSMakeRange(0, try e.className().count)).count)! > 0 {
                if debugIndicator { print("\(try e.className()): class negative -50") }
                weight -= 50
            }
            
            if (NEGATIVE?.matches(in: e.id(), options: [], range: NSMakeRange(0, e.id().count)).count)! > 0 {
                if debugIndicator { print("\(e.id()): id negative -50") }
                weight -= 50
            }
            
            let style = try e.attr("style")
            if (!style.isEmpty && (NEGATIVE_STYLE?.matches(in: style, options: [], range: NSMakeRange(0, style.count)).count)! > 0) {
                if debugIndicator { print("\(style): style negative -50") }
                weight -= 50
            }
            
            return weight
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return 0
    }
    
    /**
     * Prepares document. Currently only stipping unlikely candidates, since
     * from time to time they're getting more score than good ones especially in
     * cases when major text is short.
     *
     * @param doc document to prepare. Passed as reference, and changed inside
     *            of function
     */
    func prepareDocument(_ doc: Document, _ baseUrl: String) {
        // stripUnlikelyCandidates(doc)
        removeNav(doc)
        removeSelectsAndOptions(doc)
        removeScriptsAndStyles(doc)
        removeShares(doc)
        removeAds(doc)
        removeAuthor(doc)
        removeTitle(doc)
        removeMisc(doc)
        handleImages(doc, baseUrl)
    }
    
    /**
     * Removes unlikely candidates from HTML. Currently takes id and class name
     * and matches them against list of patterns
     *
     * @param doc document to strip unlikely candidates from
     */
    func removeNav(_ doc: Document) {
        do {
            let nav = try doc.getElementsByTag("nav")
            for item in nav {
                try item.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func removeScriptsAndStyles(_ doc: Document) {
        do {
            let scripts = try doc.getElementsByTag("script")
            for item in scripts {
                try item.remove()
            }
    
            let noscripts = try doc.getElementsByTag("noscript")
            for item in noscripts {
                try item.remove()
            }
            
            let styles = try doc.getElementsByTag("style")
            for style in styles {
                try style.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func removeSelectsAndOptions(_ doc: Document) {
        do {
            let scripts = try doc.getElementsByTag("select")
            for item in scripts {
                try item.remove()
            }
            
            let noscripts = try doc.getElementsByTag("option")
            for item in noscripts {
                try item.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func removeShares(_ doc: Document) {
        do {
            let shares = try doc.select("div[class~=(shar(e|ing)|facebook|twitter|google.*plus|whatsapp|pinterest|instagram|youtube)]")
            for item in shares {
                try item.remove()
            }
            
            let singPromosFbLikes = try doc.select("iframe[src~=facebook.*like]")
            for item in singPromosFbLikes {
                try item.remove()
            }
            
            let singPromosFbShares = try doc.select("p[id~=shareOnFacebook]")
            for item in singPromosFbShares {
                try item.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func removeAds(_ doc: Document) {
        do {
            var ads = try doc.select("div[class~=thrv_wrapper]")
            for item in ads {
                try item.remove()
            }
            
            ads = try doc.select("aside")
            for item in ads {
                try item.remove()
            }
            
            ads = try doc.select("div[class~=social-ring-button]")
            for item in ads {
                try item.remove()
            }
            
            ads = try doc.select("ins[class~=adsbygoogle]")
            for item in ads {
                try item.remove()
            }
            
            ads = try doc.select("div[id~=div-gpt-ad]")
            for item in ads {
                try item.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func removeAuthor(_ doc: Document) {
        do {
            let authors = try doc.select("div[class~=author]")
            for item in authors {
                try item.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func removeTitle(_ doc: Document) {
        do {
            let title = try doc.select("div[class~=([^a-z]title$|^title$)]")
            for item in title {
                try item.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func removeMisc(_ doc: Document) {
        do {
            // The Independent specific
            var misc = try doc.select("iframe[security~=restricted]")
            for item in misc {
                try item.remove()
            }
            
            // Seedly specific
            misc = try doc.select("a:contains(back to main blog)")
            for item in misc {
                try item.remove()
            }
            
            misc = try doc.select("div[class~=hatom-extra]")
            for item in misc {
                try item.remove()
            }
            
            //image
            misc = try doc.select("meta[property~=og:image]")
            for item in misc {
                try item.remove()
            }
            
            //title
            misc = try doc.select("meta[property~=og:title]")
            for item in misc {
                try item.remove()
            }
            
            //Miss Tam Chiak
            misc = try doc.select("h1[class~=page-title]")
            for item in misc {
                try item.remove()
            }
            misc = try doc.select("div[class~=single-post-meta]")
            for item in misc {
                try item.remove()
            }
            
            //forms
            misc = try doc.select("form")
            for item in misc {
                try item.remove()
            }
            
            //footer
            misc = try doc.select("footer")
            for item in misc {
                try item.remove()
            }
            
            //related
            misc = try doc.select("div[class~=.*related.*]")
            for item in misc {
                try item.remove()
            }
            
            //copyright
            misc = try doc.select("p[class~=copyright]")
            for item in misc {
                try item.remove()
            }
            
            //comments
            misc = try doc.select("div[class~=.*comment.*]")
            for item in misc {
                try item.remove()
            }
            
            //seedly questions
            misc = try doc.select("a[href~=.*seedly.sg/questions.*]")
            for item in misc {
                try item.remove()
            }
            
            //peatix
            misc = try doc.select("iframe[src~=peatix]")
            for item in misc {
                try item.remove()
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    func handleImages(_ doc: Document, _ baseUrl: String) {
        do {
            // ChannelNews Asia specific
            let pictures = try doc.getElementsByTag("picture")
            for picture in pictures {
                let source = picture.child(0)
                let srcset = try source.attr("srcset")
                
                let image = picture.child(1)
                try image.attr("srcset", srcset)
            }
            
            // Handle relative links
            var base: String?
            if baseUrl.suffix(1) == "/"{
                base = String(baseUrl.prefix(baseUrl.count-1))
            } else {
                base = baseUrl
            }
            let images = try doc.getElementsByTag("img")
            for image in images {
                let src = try image.attr("src")
                if src.starts(with: "//") {
                    try image.attr("src", "http://\(src)")
                } else if src.starts(with: "/") {
                    try image.attr("src", base! + src)
                }
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
    }
    
    /**
     * @return a set of all meta nodes
     */
    func getMetas(_ doc: Document) -> [Element]? {
        do {
            var nodes = [Element]()
            nodes.append(contentsOf: try doc.select("head").select("meta"))
            return nodes
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    /**
     * @return a set of all important nodes
     */
    func getNodes(_ doc: Document, selector: String?) -> [Element]? {
        let selector = selector ?? "body"
        do {
            var nodes = [Element]()
            for el in try doc.select(selector).select("*") {
                if (NODES?.matches(in: el.tagName(), options: [], range: NSMakeRange(0, el.tagName().count)).count)! > 0 {
                    nodes.append(el)
                }
            }
            return nodes
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
}
