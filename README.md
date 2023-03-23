# Swift与ChatGPT联手展示宫格翻页视图魔法

在本教程中，我们将探讨如何使用Swift语言和ChatGPT共同创建一个具有翻页功能的宫格视图组件。通过这个实例，您将了解如何将ChatGPT与现有的iOS项目相结合，以及如何自定义和优化组件以满足您的需求。


![预览图](https://p1-juejin.byteimg.com/tos-cn-i-k3u1fbpfcp/701fad9e2ecc4435bdc71fbbb8c15d2f~tplv-k3u1fbpfcp-watermark.image?)

## 开始之前

首先，我们需要确保您已经安装了所需的依赖库和软件，包括SnapKit和UIKit。这两个库在本教程中都有用到，因此请务必确保您已经正确安装了它们。

## 构建宫格翻页视图组件

在完成环境设置之后，我们将开始构建宫格翻页视图组件。首先，我们需要定义两个协议：`GridPageViewDataSource`和`GridPageViewDelegate`。这两个协议分别负责提供数据和处理事件。

```swift
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
```

接下来，我们将创建一个名为`GridPageView`的自定义视图类。这个类将继承自`UIView`，并包含一个`UICollectionView`实例。我们将使用SnapKit为`UICollectionView`设置约束，使其铺满整个`GridPageView`。

为了实现翻页功能，我们需要创建一个名为`GridPagedFlowLayout`的自定义布局类。这个类将继承自`UICollectionViewFlowLayout`，并重写相应的方法来实现翻页效果。在这个类中，我们可以自定义列数、行数、项目间距、行间距和页间距等属性。

```swift
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

```

`GridPageView`类将包含以下主要功能：

-   注册单元格
-   重新加载数据
-   处理滚动事件

```swift
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

```

## 示例代码

在实现了`GridPageView`和`GridPagedFlowLayout`之后，您可以使用以下示例代码来创建一个具有翻页功能的宫格视图组件：

```swift
// 创建并配置GridPageView实例
let gridPageView = GridPageView(columns: 4, rows: 2, itemSpacing: 10, lineSpacing: 10, pageSpacing: 20)
gridPageView.dataSource = self
gridPageView.delegate = self
view.addSubview(gridPageView)

// 实现GridPageViewDataSource和GridPageViewDelegate协议方法
func cellForItemAt(pageView: GridPageView, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
    // ...
}

func numberOfItems() -> Int {
    // ...
}

func pageView(_ pageView: GridPageView, didSelectItemAt indexPath: IndexPath) {
    // ...
}

func pageView(_ pageView: GridPageView, didChangeToPage page: Int) {
    // ...
}

func scrollViewDidScroll(_ scrollView: UIScrollView) {
    // ...
}

```

## 总结

通过本教程，您已经学会了如何使用Swift和ChatGPT共同创建一个具有翻页功能的宫格视图组件。现在，您可以将这个组件应用到您的项目中，以实现各种炫酷的效果。希望本教程对您有所帮助。在此基础上，您还可以尝试扩展和自定义组件以满足您的需求。以下是一些建议供您参考：

1.  添加动画效果：为`GridPageView`中的项目添加一些过渡或滚动动画效果，使其在滚动过程中显得更加流畅。
    
2.  支持自定义单元格：允许用户自定义每个单元格的内容和样式，使组件更具通用性和灵活性。
    
3.  支持多种布局样式：除了宫格布局之外，您还可以为`GridPageView`添加列表布局、瀑布流布局等其他布局样式。
    
4.  支持无限滚动：为`GridPageView`添加无限滚动功能，使用户在到达最后一页时能够继续滚动回到第一页。
    
5.  集成其他功能：考虑将`GridPageView`与其他组件或功能集成，例如搜索、筛选、排序等，以满足您的应用需求。
    

继续学习和探索这些功能，您将能够充分利用`GridPageView`组件，并在您的项目中实现更加丰富的视觉效果。祝您编程愉快！

## 其他

值得一提的是，本文的草稿是由 OpenAI 的 ChatGPT 生成的。ChatGPT 是一个先进的人工智能语言模型，能够生成自然、连贯的文本。在本文的生成过程中，ChatGPT 能够理解和遵循我们的指示，生成了高质量的技术文章。

然而，ChatGPT 也有一些局限性。例如，它可能会在某些情况下表述不清晰或重复内容。尽管如此，ChatGPT 仍然是一个非常有用的工具，可以帮助我们更快速地生成文章草稿，从而节省时间和精力。

[Demo](https://github.com/gongxiaokai/TagDemo)在这里
