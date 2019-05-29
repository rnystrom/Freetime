//
//  IssueCommentHtmlCell.swift
//  Freetime
//
//  Created by Ryan Nystrom on 6/22/17.
//  Copyright © 2017 Ryan Nystrom. All rights reserved.
//

import UIKit
import IGListKit

protocol IssueCommentHtmlCellDelegate: class {
    func webViewDidResize(cell: IssueCommentHtmlCell, html: String, cellWidth: CGFloat, size: CGSize)
}

protocol IssueCommentHtmlCellNavigationDelegate: class {
    func webViewWantsNavigate(cell: IssueCommentHtmlCell, url: URL)
}

protocol IssueCommentHtmlCellImageDelegate: class {
    func webViewDidTapImage(cell: IssueCommentHtmlCell, url: URL)
}

private final class IssueCommentHtmlCellWebView: UIWebView {

    override var safeAreaInsets: UIEdgeInsets {
        return .zero
    }

}

final class IssueCommentHtmlCell: IssueCommentBaseCell, ListBindable, UIWebViewDelegate {

    private static let ImgScheme = "freetime-img"
    private static let HeightScheme = "freetime-hgt"
    private static let JavaScriptHeight = "offsetHeight"

    private static let htmlHead = """
    <!DOCTYPE html><html><head><style>
    * {margin: 0;padding: 0;}
    body{
    // html whitelist: https://github.com/jch/html-pipeline/blob/master/lib/html/pipeline/sanitization_filter.rb#L45-L49
    // lint compiled style with http://csslint.net/
    font-family: -apple-system; font-size: \(Styles.Text.body.preferredFont.pointSize)px;
    color: #\(Styles.Colors.Gray.dark);
    padding: \(Styles.Sizes.columnSpacing)px 0 0;
    margin: 0;
    background-color: #ffffff;
    }
    * { font-family: -apple-system; font-size: \(Styles.Text.body.preferredFont.pointSize)px; }
    b, strong{font-weight: \(Styles.Sizes.HTML.boldWeight);}
    i, em{font-style: italic;}
    a{color: #\(Styles.Colors.Blue.medium); text-decoration: none;}
    h1{font-size: \(Styles.Text.h1.preferredFont.pointSize);}
    h2{font-size: \(Styles.Text.h2.preferredFont.pointSize);}
    h3{font-size: \(Styles.Text.h3.preferredFont.pointSize);}
    h4{font-size: \(Styles.Text.h4.preferredFont.pointSize);}
    h5{font-size: \(Styles.Text.h5.preferredFont.pointSize);}
    h6, h7, h8{font-size: \(Styles.Text.h6.preferredFont.pointSize)px; color: #\(Styles.Colors.Gray.medium);}
    dl dt{margin-top: \(Styles.Sizes.HTML.spacing)px; font-style: italic; font-weight: \(Styles.Sizes.HTML.boldWeight);}
    dl dd{padding: 0 \(Styles.Sizes.HTML.spacing)px;}
    blockquote{font-style: italic; color: #\(Styles.Colors.Gray.medium);}
    pre, code{background-color: #\(Styles.Colors.Gray.lighter); font-family: Courier;}
    pre{padding: \(Styles.Sizes.columnSpacing)px 0;}
    sub{font-size: \(Styles.Text.secondary.preferredFont.pointSize)px;}
    sub a{font-size: \(Styles.Text.secondary.preferredFont.pointSize)px;}
    table{border-spacing: 0; border-collapse: collapse;}
    th, td{border: 1px solid #\(Styles.Colors.Gray.border); padding: 6px 13px;}
    th{font-weight: \(Styles.Sizes.HTML.boldWeight); text-align: center;}
    img{max-width:100%; box-sizing: border-box; max-height: \(Styles.Sizes.maxImageHeight)px; object-fit: contain;}
    </style>
    </head><body>
    """
    private static let htmlTail = """
    <script>
        document.documentElement.style.webkitUserSelect='none';
        document.documentElement.style.webkitTouchCallout='none';
        var tapAction = function(e) {
            document.location = "\(ImgScheme)://" + encodeURIComponent(e.target.src);
        };
        function removeRootPath(img) {
            var src = img.getAttribute('src');
            if(src.length > 1 && src.indexOf('/') === 0) {
                img.src = src.substring(1, src.length);
            }
        }
        var imgs = document.getElementsByTagName('img');
        for (var i = 0; i < imgs.length; i++) {
            imgs[i].addEventListener('click', tapAction);
            removeRootPath(imgs[i]);
        }
        function onElementHeightChange(elm, callback) {
            var lastHeight = elm.\(IssueCommentHtmlCell.JavaScriptHeight), newHeight;
            (function run() {
                newHeight = elm.\(IssueCommentHtmlCell.JavaScriptHeight);
                if(lastHeight != newHeight) {
                    callback(newHeight);
                }
                lastHeight = newHeight;
                if(elm.onElementHeightChangeTimer) {
                    clearTimeout(elm.onElementHeightChangeTimer);
                }
                elm.onElementHeightChangeTimer = setTimeout(run, 300);
            })();
        }
        onElementHeightChange(document.body, function(height) {
            document.location = "\(HeightScheme)://" + height;
        });
    </script>
    </body>
    </html>
    """

    weak var delegate: IssueCommentHtmlCellDelegate?
    weak var navigationDelegate: IssueCommentHtmlCellNavigationDelegate?
    weak var imageDelegate: IssueCommentHtmlCellImageDelegate?

    @objc private let webView = IssueCommentHtmlCellWebView()
    private var body = ""
    var webViewBaseURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)

        // https://stackoverflow.com/a/23427923
        webView.isOpaque = false
        webView.backgroundColor = .clear

        webView.delegate = self
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false

        let scrollView = webView.scrollView
        scrollView.scrollsToTop = false
        scrollView.bounces = true

        contentView.addSubview(webView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        webView.alpha = 0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if webView.frame != contentView.bounds {
            webView.frame = contentView.bounds
        }
    }

    // MARK: Private API

    func changed(height: CGFloat) {
        guard isHidden == false, height != bounds.height else { return }

        let size = CGSize(width: contentView.bounds.width, height: CGFloat(height))
        delegate?.webViewDidResize(cell: self, html: body, cellWidth: size.width, size: size)
    }

    // MARK: ListBindable

    func bindViewModel(_ viewModel: Any) {
        guard let viewModel = viewModel as? IssueCommentHtmlModel else { return }
        configure(with: viewModel)
    }

    func configure(with model: IssueCommentHtmlModel) {
        body = model.html
        // hack that appends a trailing slash if its missing
        // required to load raw images
        webViewBaseURL = model.baseURL?.appendingPathComponent("", isDirectory: false)

        let html = IssueCommentHtmlCell.htmlHead + body + IssueCommentHtmlCell.htmlTail
        webView.loadHTMLString(html, baseURL: webViewBaseURL)
    }

    // MARK: UIWebViewDelegate

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        // if the cell is hidden, its been put back in the reuse pool
        guard isHidden == false, let url = request.url else { return true }

        if url.scheme == IssueCommentHtmlCell.ImgScheme,
            let host = url.host,
            let imageURL = URL(string: host) {
            imageDelegate?.webViewDidTapImage(cell: self, url: imageURL)
            return false
        } else if url.scheme == IssueCommentHtmlCell.HeightScheme,
            let heightString = url.host as NSString? {
            changed(height: CGFloat(heightString.floatValue))
            return false
        }

        if let baseURL = webViewBaseURL, url == baseURL {
            return true
        }

        let htmlLoad = url.absoluteString == "about:blank"
        if !htmlLoad {
            navigationDelegate?.webViewWantsNavigate(cell: self, url: url)
        }
        return htmlLoad
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        webView.alpha = 1

        if let heightString = webView
            .stringByEvaluatingJavaScript(from: "document.body.\(IssueCommentHtmlCell.JavaScriptHeight)") as NSString? {
            changed(height: CGFloat(heightString.floatValue))
        }
    }

}
