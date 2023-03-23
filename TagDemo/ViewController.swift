//
//  ViewController.swift
//  TagDemo
//
//  Created by kk on 2023/3/13.
//

import SnapKit
import UIKit

class ViewController: UIViewController {
    lazy var tagsView: TagsView = {
        let view = TagsView()
        view.backgroundColor = .yellow
        return view
    }()

    lazy var pageView: GridPageView = {
        let view = GridPageView(columns: 4, rows: 3, itemSpacing: 10, lineSpacing: 10, pageSpacing: 10)
        view.dataSource = self
        view.delegate = self
        view.backgroundColor = .yellow
        view.registerCell(CustomCell.self, forCellWithReuseIdentifier: CustomCell.reuseIdentifier)
        return view
    }()

    var data: [String] = Array(0 ..< 15).map { "Item \($0)" }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tagsView)
        tagsView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalTo(view.layoutMarginsGuide)
            $0.height.equalTo(200)
        }
        tagsView.data = [
            "测试据123",
            "测试123123123",
            "测试数测试数测试数测试数",
            "测试测",
            "测试测试",
            "测试数",
            "测试",
            "测试数",
            "测据12据12据12据123",
            "测据123",
        ]
//        tagsView.data = (0..<(Int.random(in: 10..<20))).map{ i in
//            return "测试数据\(i)-\(Int.random(in: 10..<1000000))"
//        }

        view.addSubview(pageView)
        pageView.snp.makeConstraints {
            $0.left.equalTo(10)
            $0.right.equalTo(-10)
            $0.top.equalTo(tagsView.snp.bottom).offset(20)
            $0.height.equalTo(200)
        }

        let btn = UIButton()
        btn.setTitle("Reload", for: .normal)
        btn.backgroundColor = .black
        view.addSubview(btn)
        btn.snp.makeConstraints {
            $0.width.height.equalTo(100)
            $0.top.equalTo(pageView.snp.bottom).offset(100)
            $0.centerX.equalToSuperview()
        }
        btn.addTarget(self, action: #selector(changeData), for: .touchUpInside)
    }

    @objc func changeData() {
        let max = Int.random(in: 5..<30)
        data = (0 ..< max).map { "Item \($0) - \(max)" }
        pageView.rows = Int.random(in: 1..<5)
        pageView.columns = Int.random(in: 1..<5)
        pageView.lineSpacing = CGFloat(Int.random(in: 10..<20))
        pageView.itemSpacing = CGFloat(Int.random(in: 10..<20))
        pageView.pageSpacing = CGFloat(Int.random(in: 10..<20))
        pageView.reloadData()
    }
}

extension ViewController: GridPageViewDataSource, GridPageViewDelegate {
    func numberOfItems() -> Int {
        return data.count
    }

    func cellForItemAt(pageView: GridPageView, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CustomCell.reuseIdentifier, for: indexPath) as! CustomCell
        cell.title = data[indexPath.item]
        return cell
    }

    func pageView(_ pageView: GridPageView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItemAt: \(indexPath)")
    }

    func pageView(_ pageView: GridPageView, didChangeToPage page: Int) {
        print("Current page: \(page)")
    }
}

class CustomCell: UICollectionViewCell {
    static let reuseIdentifier = "CustomCell"

    private lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .black
        label.numberOfLines = 0
        return label
    }()

    var title: String? {
        didSet {
            label.text = title
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .orange
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
