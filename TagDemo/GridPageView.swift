//
//  PageView.swift
//  TagDemo
//
//  Created by kk on 2023/3/21.
//

import SnapKit
import UIKit

protocol GridPageViewDataSource: AnyObject {
    func cellForItemAt(pageView: GridPageView, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell
    func numberOfItems() -> Int
}

protocol GridPageViewDelegate: AnyObject {
    func pageView(_ pageView: GridPageView, didSelectItemAt indexPath: IndexPath)
    func pageView(_ pageView: GridPageView, didChangeToPage page: Int)
    func scrollViewDidScroll(_ scrollView: UIScrollView)
}

extension GridPageViewDelegate {
    func pageView(_ pageView: GridPageView, didSelectItemAt indexPath: IndexPath) {}
    func pageView(_ pageView: GridPageView, didChangeToPage page: Int) {}
    func scrollViewDidScroll(_ scrollView: UIScrollView) {}
}

class GridPageView: UIView {
    weak var dataSource: GridPageViewDataSource?
    weak var delegate: GridPageViewDelegate?

    /// 列数
    var columns: Int {
        get {
            (collectionView.collectionViewLayout as? GridPagedFlowLayout)?.columns ?? 0
        }
        set {
            if let layout = collectionView.collectionViewLayout as? GridPagedFlowLayout {
                layout.columns = newValue
                layout.invalidateLayout()
            }
        }
    }

    /// 行数
    var rows: Int {
        get {
            (collectionView.collectionViewLayout as? GridPagedFlowLayout)?.rows ?? 0
        }
        set {
            if let layout = collectionView.collectionViewLayout as? GridPagedFlowLayout {
                layout.rows = newValue
                layout.invalidateLayout()
            }
        }
    }

    /// 列间距
    var itemSpacing: CGFloat {
        get {
            (collectionView.collectionViewLayout as? GridPagedFlowLayout)?.itemSpacing ?? 0
        }
        set {
            if let layout = collectionView.collectionViewLayout as? GridPagedFlowLayout {
                layout.itemSpacing = newValue
                layout.invalidateLayout()
            }
        }
    }

    /// 行间距
    var lineSpacing: CGFloat {
        get {
            (collectionView.collectionViewLayout as? GridPagedFlowLayout)?.lineSpacing ?? 0
        }
        set {
            if let layout = collectionView.collectionViewLayout as? GridPagedFlowLayout {
                layout.lineSpacing = newValue
                layout.invalidateLayout()
            }
        }
    }

    /// 页边距
    var pageSpacing: CGFloat {
        get {
            (collectionView.collectionViewLayout as? GridPagedFlowLayout)?.pageSpacing ?? 0
        }
        set {
            if let layout = collectionView.collectionViewLayout as? GridPagedFlowLayout {
                layout.pageSpacing = newValue
                layout.invalidateLayout()
            }
        }
    }

    private var displayLink: CADisplayLink?
    private var targetOffset: CGFloat = 0
    private var initialOffset: CGFloat = 0
    private var startTime: TimeInterval = 0
    private(set) var collectionView: UICollectionView!

    public init(columns: Int = 4, rows: Int = 2, itemSpacing: CGFloat = 10, lineSpacing: CGFloat = 10, pageSpacing: CGFloat = 20) {
        let layout = GridPagedFlowLayout(columns: columns, rows: rows, itemSpacing: itemSpacing, lineSpacing: lineSpacing, pageSpacing: pageSpacing)
        super.init(frame: .zero)
        setupCollectionView(with: layout)
        setupStyle()
    }

    private func setupCollectionView(with layout: GridPagedFlowLayout) {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isPagingEnabled = false
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.contentInset = .zero
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStyle() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateScrollOffset))
        startTime = CACurrentMediaTime()
        displayLink?.add(to: .current, forMode: .common)
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateScrollOffset(displayLink: CADisplayLink) {
        let elapsedTime = CACurrentMediaTime() - startTime
        let duration = 0.25
        let progress = min(elapsedTime / duration, 1)
        let easedProgress = ease(CGFloat(progress))
        let interpolatedOffset = initialOffset + (targetOffset - initialOffset) * easedProgress

        if progress >= 1 {
            collectionView.contentOffset = CGPoint(x: targetOffset, y: collectionView.contentOffset.y)
            stopDisplayLink()
        } else {
            collectionView.contentOffset = CGPoint(x: interpolatedOffset, y: collectionView.contentOffset.y)
        }
    }

    private func ease(_ t: CGFloat) -> CGFloat {
        return t * t
    }

    private func adjustContentOffset() {
        guard let collectionView = collectionView, let flowLayout = collectionView.collectionViewLayout as? GridPagedFlowLayout else { return }

        let pageWidth = collectionView.bounds.width + flowLayout.pageSpacing
        let contentInset = collectionView.contentInset.left
        let rawPageValue = (collectionView.contentOffset.x + contentInset) / pageWidth
        let currentPage = round(rawPageValue)

        let totalPages = ceil(CGFloat(collectionView.numberOfItems(inSection: 0)) / CGFloat(flowLayout.columns * flowLayout.rows))
        let clampedPage = max(min(currentPage, totalPages - 1), 0)

        let nextPageOffset = (clampedPage * pageWidth) - contentInset
        collectionView.contentOffset = CGPoint(x: nextPageOffset, y: collectionView.contentOffset.y)
    }
}

// MARK: - Public

extension GridPageView {
    public func registerCell<T: UICollectionViewCell>(_ cellClass: T.Type, forCellWithReuseIdentifier identifier: String) {
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }

    public func reloadData() {
        collectionView.reloadData()
        stopDisplayLink()
        adjustContentOffset()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate

extension GridPageView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource?.numberOfItems() ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = dataSource?.cellForItemAt(pageView: self, collectionView: collectionView, indexPath: indexPath) {
            return cell
        }
        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = delegate {
            delegate.pageView(self, didSelectItemAt: indexPath)
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let collectionView = scrollView as? UICollectionView, let flowLayout = collectionView.collectionViewLayout as? GridPagedFlowLayout else { return }

        let pageWidth = collectionView.bounds.width + flowLayout.pageSpacing
        let targetXContentOffset = targetContentOffset.pointee.x
        let contentInset = collectionView.contentInset.left
        let rawPageValue = (targetXContentOffset + contentInset) / pageWidth

        let currentPage: CGFloat
        if velocity.x > 0 {
            currentPage = ceil(rawPageValue)
        } else if velocity.x < 0 {
            currentPage = floor(rawPageValue)
        } else {
            currentPage = round(rawPageValue)
        }

        let totalPages = ceil(CGFloat(collectionView.numberOfItems(inSection: 0)) / CGFloat(flowLayout.columns * flowLayout.rows))
        let clampedPage = max(min(currentPage, totalPages - 1), 0)

        let nextPageOffset = (clampedPage * pageWidth) - contentInset
        targetContentOffset.pointee = scrollView.contentOffset

        initialOffset = scrollView.contentOffset.x
        targetOffset = nextPageOffset
        startDisplayLink()

        delegate?.pageView(self, didChangeToPage: Int(clampedPage))
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.scrollViewDidScroll(scrollView)
    }
}

// MARK: - GridPagedFlowLayout

class GridPagedFlowLayout: UICollectionViewFlowLayout {
    var columns: Int
    var rows: Int
    var itemSpacing: CGFloat
    var lineSpacing: CGFloat
    var pageSpacing: CGFloat

    private var allAttributes: [UICollectionViewLayoutAttributes] = []

    init(columns: Int, rows: Int, itemSpacing: CGFloat, lineSpacing: CGFloat, pageSpacing: CGFloat) {
        self.columns = columns
        self.rows = rows
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
        self.pageSpacing = pageSpacing
        super.init()
        self.scrollDirection = .horizontal
        self.minimumLineSpacing = itemSpacing
        self.minimumInteritemSpacing = lineSpacing
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }
        let contentWidth = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
        let contentHeight = collectionView.bounds.height - collectionView.contentInset.top - collectionView.contentInset.bottom
        let itemWidth = (contentWidth - CGFloat(columns - 1) * itemSpacing) / CGFloat(columns)
        let itemHeight = (contentHeight - CGFloat(rows - 1) * lineSpacing) / CGFloat(rows)
        itemSize = CGSize(width: itemWidth, height: itemHeight)

        allAttributes = []

        let totalItems = collectionView.numberOfItems(inSection: 0)
        for itemIndex in 0 ..< totalItems {
            let indexPath = IndexPath(item: itemIndex, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)

            let page = itemIndex / (columns * rows)
            let remainingIndex = itemIndex % (columns * rows)
            let xPosition = CGFloat(remainingIndex % columns) * (itemWidth + itemSpacing) + CGFloat(page) * (contentWidth + pageSpacing)
            let yPosition = CGFloat(remainingIndex / columns) * (itemHeight + lineSpacing)
            attributes.frame = CGRect(x: xPosition, y: yPosition, width: itemWidth, height: itemHeight)

            allAttributes.append(attributes)
        }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return allAttributes.filter { rect.intersects($0.frame) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return allAttributes[indexPath.item]
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else { return .zero }
        let totalPages = ceil(CGFloat(collectionView.numberOfItems(inSection: 0)) / CGFloat(columns * rows))
        let width = (totalPages - 1) * pageSpacing + totalPages * collectionView.bounds.width
        return CGSize(width: width, height: collectionView.bounds.height)
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return .zero }

        let pageWidth = collectionView.bounds.width + pageSpacing
        let contentInset = collectionView.contentInset.left
        let rawPageValue = (collectionView.contentOffset.x + contentInset) / pageWidth

        let currentPage: CGFloat
        if velocity.x > 0 {
            currentPage = ceil(rawPageValue)
        } else if velocity.x < 0 {
            currentPage = floor(rawPageValue)
        } else {
            currentPage = round(rawPageValue)
        }

        let nextPageOffset = (currentPage * pageWidth) - contentInset
        return CGPoint(x: nextPageOffset, y: proposedContentOffset.y)
    }
}
