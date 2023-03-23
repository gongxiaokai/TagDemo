//
//  TagsView.swift
//  TagDemo
//
//  Created by kk on 2023/3/13.
//

import Foundation
import SnapKit
import UIKit

class TagsView: UIView {
    lazy var layout: WaterfallFlowLayout = {
        let layout = WaterfallFlowLayout(delegate: self, numberOfColumns: 5, miniumLineSpacing: 10, miniumInteritemSpacing: 10)
        return layout
    }()
    
    lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        view.backgroundColor = .green
        view.register(TagsCell.self, forCellWithReuseIdentifier: "TagsCell")
        view.delegate = self
        view.dataSource = self
        return view
    }()
    
    var data: [String] = [] {
        didSet {
//            layout.invalidateLayout()
            collectionView.reloadData()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupStyle() {
        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension TagsView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagsCell", for: indexPath) as! TagsCell
        cell.title = data[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("点击 = \(indexPath)")
    }
}

extension TagsView: WaterfallFlowLayoutDelegate {
    func widthForItem(indexPath: IndexPath) -> CGFloat {
        let leftMargin: CGFloat = 20
        let rightMargin: CGFloat = 20
        let width = (data[indexPath.item] as NSString).size(withAttributes: [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)
        ]).width + leftMargin + rightMargin
        return width
    }
}

class TagsCell: UICollectionViewCell {
    var title: String = "" {
        didSet {
            self.titleLab.text = title
        }
    }
    
    lazy var titleLab: UILabel = {
        let lab = UILabel()
        lab.font = UIFont.systemFont(ofSize: 17)
        return lab
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStyle()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupStyle() {
        contentView.addSubview(titleLab)
        contentView.backgroundColor = .systemBlue
        titleLab.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }
}

protocol WaterfallFlowLayoutDelegate: NSObjectProtocol {
    func widthForItem(indexPath: IndexPath) -> CGFloat
}

class WaterfallFlowLayout: UICollectionViewLayout {
    weak var delegate: WaterfallFlowLayoutDelegate!
    
    /// 最大列
    var numberOfColumns = 2 {
        didSet {
            guard oldValue != numberOfColumns else { return }
            invalidateLayout()
        }
    }
    
    var miniumLineSpacing: CGFloat = 10 {
        didSet {
            guard oldValue != miniumLineSpacing else { return }
            invalidateLayout()
        }
    }
    
    var miniumInteritemSpacing: CGFloat = 10 {
        didSet {
            guard oldValue != miniumInteritemSpacing else { return }
            invalidateLayout()
        }
    }
    
    var sectionInset = UIEdgeInsets.zero {
        didSet {
            guard oldValue != sectionInset else { return }
            invalidateLayout()
        }
    }

    /// 记录每一列布局到的宽度
    private(set) var widthOfColumns: [CGFloat] = []
    /// 缓存attributes
    private(set) var itemAttributes: [UICollectionViewLayoutAttributes] = []
    
    init(delegate: WaterfallFlowLayoutDelegate,
         numberOfColumns: Int = 2,
         miniumLineSpacing: CGFloat,
         miniumInteritemSpacing: CGFloat,
         sectionInset: UIEdgeInsets = UIEdgeInsets.zero)
    {
        self.delegate = delegate
        self.numberOfColumns = numberOfColumns
        self.miniumLineSpacing = miniumLineSpacing
        self.miniumInteritemSpacing = miniumInteritemSpacing
        self.sectionInset = sectionInset
        super.init()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        if itemAttributes.count > 0 {
            itemAttributes.removeAll()
        }
        if widthOfColumns.count > 0 {
            widthOfColumns.removeAll()
        }
        
        (0..<numberOfColumns).forEach { _ in
            widthOfColumns.append(sectionInset.left)
        }
        
        let count = collectionView?.numberOfItems(inSection: 0) ?? 0
        
        let totalHeight = collectionView?.frame.size.height ?? 0
        let validHeight = totalHeight - sectionInset.top - sectionInset.bottom - (CGFloat(numberOfColumns - 1) * miniumInteritemSpacing)
        
        let itemHeight = validHeight / CGFloat(numberOfColumns)
        
        var itemWidth = itemHeight
        
        for i in 0..<count {
            let index = indexOfShortestColumn()
            let originY = sectionInset.top + CGFloat(index) * (itemHeight + miniumInteritemSpacing)
            let originX = widthOfColumns[index]
            
            let indexPath = IndexPath(item: i, section: 0)
            itemWidth = delegate?.widthForItem(indexPath: indexPath) ?? itemWidth
            let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attr.frame = CGRect(x: originX, y: originY, width: itemWidth, height: itemHeight)
            itemAttributes.append(attr)
            widthOfColumns[index] = originX + itemWidth + miniumLineSpacing
        }
        collectionView?.reloadData()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        // 判断两个矩形是否有交集
        return itemAttributes.filter { $0.frame.intersects(rect) }
    }
    
    override var collectionViewContentSize: CGSize {
        // 最终content尺寸
        let height = collectionView?.frame.size.height ?? 0
        let index = indexOfLongestColumn()
        let width = widthOfColumns[index] + sectionInset.right - miniumLineSpacing
        return CGSize(width: width, height: height)
    }
    
    /// 找到最长列
    func indexOfLongestColumn() -> Int {
        var index = 0
        for i in 0..<numberOfColumns {
            if widthOfColumns[i] > widthOfColumns[index] {
                index = i
            }
        }
        return index
    }
    
    /// 找到最短列
    func indexOfShortestColumn() -> Int {
        var index = 0
        for i in 0..<numberOfColumns {
            if widthOfColumns[i] < widthOfColumns[index] {
                index = i
            }
        }
        return index
    }
}
