//
//  HtmlUtils.swift
//  Acorn
//
//  Created by macOS on 16/8/18.
//  Copyright © 2018 macOS. All rights reserved.
//

import Foundation
import UIKit
import SwiftSoup

class HtmlUtils {
    var WHITELIST: Whitelist?
    
    let nightModeOn = UserDefaults.standard.bool(forKey: "nightModePref")
    
    let IMG_PATTERN = try? NSRegularExpression(pattern:"(<img)[^>]*\\ssrc=\\s*['\"]([^'\"]+)['\"][^>]*>", options: .caseInsensitive)
    let ADS_PATTERN = try? NSRegularExpression(pattern:"<div class=['\"](mf-viral)['\"]><table border=['\"]0['\"]>.*", options: .caseInsensitive)
    let SEEDLY_IMG_DESC_PATTERN = try? NSRegularExpression(pattern:"data-image-description=['\"][^'\"]['\"]", options: .caseInsensitive)
    let LAZY_LOADING_PATTERN = try? NSRegularExpression(pattern:"(<img)[^>]*\\s(data-lazy-src|original-src|data-src|original[ˆ>\\s]*?src|data[ˆ>\\s]*?src|data-original)=\\s*['\"]([^'\"]+)['\"]", options: .caseInsensitive)
    let CNA_IMAGE_PATTERN = try? NSRegularExpression(pattern:"<picture\\s.*?<source[ˆ>]*srcset=['\"]([ˆ'\"]+)['\"][ˆ>]*>.*?<img\\s[ˆ>]+src=['\"]([ˆ'\"]+)['\"][ˆ>]+/>.*?</picture>", options: .caseInsensitive)
    let EMPTY_IMAGE_PATTERN = try? NSRegularExpression(pattern:"<img\\s+(height=['\"]1['\"]\\s+width=['\"]1['\"]|width=['\"]1['\"]\\s+height=['\"]1['\"])\\s+[^>]*src=\\s*['\"]([^'\"]+)['\"][^>]*>", options: .caseInsensitive)
    let RELATIVE_IMAGE_PATTERN = try? NSRegularExpression(pattern:"\\s+(href|src)=\\s*?[\"'](//[^'\">\\s]+)['\"]", options: .caseInsensitive)
    let RELATIVE_IMAGE_PATTERN_2 = try? NSRegularExpression(pattern:"\\s+(href|src)=\\s*?[\"'](/[^/][^'\">\\s]+)['\"]", options: .caseInsensitive)
    let ALT_IMAGE_PATTERN = try? NSRegularExpression(pattern:"amp-img\\s", options: .caseInsensitive)
    let BAD_IMAGE_PATTERN = try? NSRegularExpression(pattern:"<img\\s+[^>]*src=\\s*['\"]([^'\"]+)\\.img['\"][^>]*>", options: .caseInsensitive)
    let START_BR_PATTERN = try? NSRegularExpression(pattern:"^(\\s*<br\\s*[/]*>\\s*)*", options: .caseInsensitive)
    let END_BR_PATTERN = try? NSRegularExpression(pattern:"(\\s*<br\\s*[/]*>\\s*)*$", options: .caseInsensitive)
    let MULTIPLE_BR_PATTERN = try? NSRegularExpression(pattern:"(\\s*<br\\s*[/]*>\\s*){3,}", options: .caseInsensitive)
    let EMPTY_LINK_PATTERN = try? NSRegularExpression(pattern:"<a\\s+[^>]*></a>", options: .caseInsensitive)
    let TABLE_START_PATTERN = try? NSRegularExpression(pattern:"(<table)", options: .caseInsensitive)
    let TABLE_END_PATTERN = try? NSRegularExpression(pattern:"(</table>)", options: .caseInsensitive)
    
    lazy var BACKGROUND_COLOR = nightModeOn ? ResourcesNight.WEBVIEW_BG_COLOR_HEX : ResourcesDay.WEBVIEW_BG_COLOR_HEX
    lazy var TEXT_COLOR = nightModeOn ? ResourcesNight.WEBVIEW_TEXT_COLOR_HEX : ResourcesDay.WEBVIEW_TEXT_COLOR_HEX
    lazy var SUBTITLE_COLOR = nightModeOn ? ResourcesNight.WEBVIEW_SUBTITLE_COLOR_HEX : ResourcesDay.WEBVIEW_SUBTITLE_COLOR_HEX
    lazy var QUOTE_BACKGROUND_COLOR = nightModeOn ? ResourcesNight.WEBVIEW_QUOTE_BG_COLOR_HEX : ResourcesDay.WEBVIEW_QUOTE_BG_COLOR_HEX
    let QUOTE_LEFT_COLOR = "#a6a6a6"
    let QUOTE_TEXT_COLOR = "#565656"
    let BUTTON_COLOR = "#52A7DF"
    let SUBTITLE_BORDER_COLOR = "solid #ddd"
    
    let BODY_START = "<body>"
    let BODY_END = "</body>"
    let TITLE_START = "<h1><a href='"
    let TITLE_MIDDLE = "'>"
    let TITLE_END = "</a></h1>"
    let SUBTITLE_START = "<p class='subtitle'>"
    let SUBTITLE_END = "</p>"
    
    func improveHtmlContent(content: String, baseUrl: String, aid: String, link: String) -> String {
        var content = content
        // remove some ads
        content = (ADS_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: ""))!
        // remove interfering elements
        content = (SEEDLY_IMG_DESC_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: ""))!
        // remove lazy loading images stuff
        content = (LAZY_LOADING_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: "$1 src=\"$3\""))!
        // fix relative image paths
        content = (RELATIVE_IMAGE_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: " $1=\"http://$2\""))!
        // fix alternative image tags
        content = (ALT_IMAGE_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: "img "))!
        
        //content = (CNA_IMAGE_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: "<img src=\"$2\" srcset=$1>"))!
        
        // clean by SwiftSoup
        do {
            WHITELIST = try Whitelist.relaxed().preserveRelativeLinks(true)
                .addTags("iframe", "video", "audio", "source", "track", "img", "span", "figcaption")
                .addAttributes("iframe", "src", "frameborder", "height", "width")
                .addAttributes("video", "src", "controls", "height", "width", "poster")
                .addAttributes("audio", "src", "controls")
                .addAttributes("source", "src", "type")
                .addAttributes("track", "src", "kind", "srclang", "label")
                .addAttributes("img", "alt", "src", "srcset")

            content = try SwiftSoup.clean(content, baseUrl, WHITELIST!)!
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        
        content = (RELATIVE_IMAGE_PATTERN_2?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: " $1=\"" + baseUrl + "$2\""))!
        
        // replace all images with appropriate image from srcset or api derived images
        let encodedLink = link.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
        var replaced = content
        var srcset: [String]?
        var offset = 0
        IMG_PATTERN?.enumerateMatches(in: content, options: [], range: NSMakeRange(0, content.count), using: { (imgResult, flags, stop) in
            let srcsetPattern = try? NSRegularExpression(pattern:"<img\\s[^>]*srcset=\\s*['\"]([^'\"]+)['\"][^>]*>", options: .caseInsensitive)
            let imageTagRange = imgResult?.range(at: 0)
            var hasSrc = false
            // if srcset exists, loop through src to find src closest to 500w
            if let imageTagRange = imageTagRange {
                let imageTag = (content as NSString).substring(with: imageTagRange)
                srcsetPattern?.enumerateMatches(in: imageTag, options: [], range: NSMakeRange(0, imageTag.count), using: { (srcsetResult, flags, stop) in
                    let srcsetRange = srcsetResult?.range(at: 1)
                    if let srcsetRange = srcsetRange {
                        srcset = (imageTag as NSString).substring(with: srcsetRange).components(separatedBy: "w,")
                        if let srcset = srcset {
                            var smallestDiff = 10000
                            var srcUrl = ""
                            for s in srcset {
                                let splitSrc = s.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
                                if (splitSrc.count > 1) {
                                    let diff = Int(splitSrc[1].split(separator: "w")[0])! - 500
                                    if (diff > 0 && diff < smallestDiff) {
                                        smallestDiff = diff
                                        srcUrl = String(s.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")[0])
                                        srcUrl = srcUrl.replacingOccurrences(of: "amp;", with: "").replacingOccurrences(of: "038;", with: "")
                                        hasSrc = true
                                    }
                                }
                            }
                            if hasSrc {
                                let replacementValue = "<img src=\"\(srcUrl)\">"
                                print(replacementValue)
                                var replacementRange = imgResult?.range
                                replacementRange?.location += offset
                                if let replacementRange = replacementRange {
                                    if let subRange = Range<String.Index>(replacementRange, in: replaced) {
                                        replaced.replaceSubrange(subRange, with: replacementValue)
                                    }
                                }
                                offset += replacementValue.count - (replacementRange?.length ?? 0)
                            }
                        }
                    }
                })
                // if no srcset, use imageResize api to generate a src
                if !hasSrc {
                    let imageUrlRange = imgResult?.range(at: 2)
                    if let imageUrlRange = imageUrlRange {
                        var imageUrl = (content as NSString).substring(with: imageUrlRange)
                        imageUrl = imageUrl.replacingOccurrences(of: "amp;", with: "").replacingOccurrences(of: "038;", with: "")
                        let encodedImageUrl = imageUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                        if let encodedImageUrl = encodedImageUrl, let encodedLink = encodedLink {
                            let replacementValue = "<img src=\"https://acorncommunity.sg/api/v1/imageResize?url=\(encodedImageUrl)&aid=\(aid)&link=\(encodedLink)\">"
                            print(replacementValue)
                            var replacementRange = imgResult?.range
                            replacementRange?.location += offset
                            if let replacementRange = replacementRange {
                                if let subRange = Range<String.Index>(replacementRange, in: replaced) {
                                    replaced.replaceSubrange(subRange, with: replacementValue)
                                }
                            }
                            offset += replacementValue.count - (replacementRange?.length ?? 0)
                        }
                    }
                }
            }
        })
        
        // remove empty or bad images
        content = (EMPTY_IMAGE_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: ""))!
        content = (BAD_IMAGE_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: ""))!
        // remove empty links
        content = (EMPTY_LINK_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: ""))!
        // remove trailing BR & too much BR
        content = (START_BR_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: ""))!
        content = (END_BR_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: ""))!
        content = (MULTIPLE_BR_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: "<br><br>"))!
        // add container to tables
        content = (TABLE_START_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: "<div class=\"container\">$1"))!
        content = (TABLE_END_PATTERN?.stringByReplacingMatches(in: content, options: [], range: NSMakeRange(0, content.count), withTemplate: "$1</div>"))!
    
        return content
    }
    
    func generateHtmlContent(_ title: String, _ link: String?, _ contentText: String, _ author: String?, _ source: String?, _ date: String?) -> String {
        var link = link
        
        let CSS = "<head><style type='text/css'> "
            + "body {max-width: 100%; margin: 0.3cm; font-family: '-apple-system','HelveticaNeue'; font-size: 16; text-align: left; color: \(TEXT_COLOR); background-color: \(BACKGROUND_COLOR); line-height: 150%} "
            + "* {max-width: 100%} "
            + "h1, h2 {line-height: 130%} "
            + "h1 {font-size: 110%; font-weight: 700, margin-bottom: 0.1em} "
            + "h2 {font-size: 110%; font-weight: 500} "
            + "h3 {font-size: 100%;} "
            + "a {color: #0099CC} "
            + "h1 a {font-weight: 1000; color: inherit; text-decoration: none} "
            + "img {height: auto} "
            + "img.avatar {vertical-align: middle; width: 16px; height: 16px; border-radius: 50%;} "
            + "figcaption {font-size: 80%} "
            //+ "pre {white-space: pre-wrap;} "
            + "blockquote {border-left: thick solid \(QUOTE_LEFT_COLOR); background-color:\(QUOTE_BACKGROUND_COLOR); margin: 0.5em 0 0.5em 0em; padding: 0.5em} "
            + "blockquote p {color: \(QUOTE_TEXT_COLOR)} "
            + "p {margin: 0.8em 0 0.8em 0} "
            + "p.subtitle {font-size: 80%; color: \(SUBTITLE_COLOR); border-top:1px \(SUBTITLE_BORDER_COLOR); border-bottom:1px \(SUBTITLE_BORDER_COLOR); padding-top:2px; padding-bottom:2px; font-weight:800 } "
            + "ul, ol {margin: 0 0 0.8em 0.6em; padding: 0 0 0 1em} "
            + "ul li, ol li {margin: 0 0 0.8em 0; padding: 0} "
            + "div.button-section {padding: 0.4cm 0; margin: 0; text-align: center} "
            + "div.container {width: 100%; overflow: auto; white-space: nowrap;} "
            + "table, th, td {border-collapse: collapse; border: 1px solid darkgray; font-size: 90%} "
            + "th, td {padding: .2em 0.5em;} "
            + ".button-section p {margin: 0.1cm 0 0.2cm 0} "
            + ".button-section p.marginfix {margin: 0.5cm 0 0.5cm 0} "
            + ".button-section input, .button-section a {font-family: roboto; font-size: 100%; color: #FFFFFF; background-color: \(BUTTON_COLOR); text-decoration: none; border: none; border-radius:0.2cm; padding: 0.3cm} "
            + "</style><meta name='viewport' content='width=device-width'/></head>"
        
        let content: StringBuilder = StringBuilder(string: CSS).append(BODY_START)
        
        if (link == nil) {
            link = ""
        }
        
        content.append(TITLE_START).append(link!).append(TITLE_MIDDLE).append(title).append(TITLE_END)
    
        var hasSubtitle = false
        
        if (date != nil && date != "") {
            content.append(SUBTITLE_START).append(date!)
            hasSubtitle = true
        }
        
        if (author != nil && author != "") {
            if (!hasSubtitle) {
                content.append(author!)
            } else {
                content.append(" · ").append(author!)
            }
            hasSubtitle = true
        }
        
        if (source != nil && source != "" && source != author) {
            if (!hasSubtitle) {
                content.append(source!)
            } else {
                content.append(" · ").append(source!)
            }
            hasSubtitle = true
        }
        
        if (hasSubtitle) {
            content.append(SUBTITLE_END)
        }
        content.append(contentText).append(BODY_END)
    
//        print(content.toString())
        return content.toString()
    }
    
    func regenArticleHtml(_ link: String, _ title: String, _ author: String, _ source: String, _ date: String, _ selector: String?, _ aid: String) -> String? {
        let baseUrlPattern = try? NSRegularExpression(pattern:"(https?://.*?/).*", options: .caseInsensitive)
        let baseUrl = baseUrlPattern?.stringByReplacingMatches(in: link, options: [], range: NSMakeRange(0, link.count), withTemplate: "$1")
        var parsedHtml: String
        
        guard let url = URL(string: link) else {
            return nil
        }
        
        do {
            let htmlString = try String(contentsOf: url)
            if let extractedHtml = ArticleTextExtractor().extractContent(input: htmlString, selector: selector, baseUrl: baseUrl!) {
                parsedHtml = improveHtmlContent(content: extractedHtml, baseUrl: baseUrl!, aid: aid, link: link)
                return generateHtmlContent(title, link, parsedHtml, author, source, date)
            } else {
                return nil
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func getCleanedHtml(_ link: String, _ selector: String?, _ aid: String) -> String? {
        let baseUrlPattern = try? NSRegularExpression(pattern:"(https?://.*?/).*", options: .caseInsensitive)
        let baseUrl = baseUrlPattern?.stringByReplacingMatches(in: link, options: [], range: NSMakeRange(0, link.count), withTemplate: "$1")
        var parsedHtml: String
        
        guard let url = URL(string: link) else {
            return nil
        }
        
        do {
            let htmlString = try String(contentsOf: url)
            if let extractedHtml = ArticleTextExtractor().extractContent(input: htmlString, selector: selector, baseUrl: baseUrl!) {
                parsedHtml = improveHtmlContent(content: extractedHtml, baseUrl: baseUrl!, aid: aid, link: link)
                return parsedHtml
            } else {
                return nil
            }
        } catch Exception.Error(_, let message) {
            print(message)
        } catch let error {
            print(error)
        }
        return nil
    }
    
    func cleanHtmlContent(html: String, link: String, selector: String?, aid: String) -> String? {
        let baseUrlPattern = try? NSRegularExpression(pattern:"(https?://.*?/).*", options: .caseInsensitive)
        let baseUrl = baseUrlPattern?.stringByReplacingMatches(in: link, options: [], range: NSMakeRange(0, link.count), withTemplate: "$1")
        var parsedHtml: String
        
        if let extractedHtml = ArticleTextExtractor().extractContent(input: html, selector: selector, baseUrl: baseUrl!) {
            parsedHtml = improveHtmlContent(content: extractedHtml, baseUrl: baseUrl!, aid: aid, link: link)
            return parsedHtml
        } else {
            return nil
        }
    }
}
