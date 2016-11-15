//  Nony
//
//  Created by Geemakun Storey on 2016-11-08.
//  Copyright © 2016 Razeware LLC. All rights reserved.

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet var mainScrollView: UIScrollView!
    @IBOutlet var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: UIButton!
    
    
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "Info"
    
        mainScrollView.delegate = self
        mainScrollView.frame = view.frame
        
        imageArray = [#imageLiteral(resourceName: "NonyNew"), #imageLiteral(resourceName: "NonyReport")]
        
        for i in 0..<imageArray.count {
            
            let imageView = UIImageView()
            imageView.image = imageArray[i]
            imageView.contentMode = .scaleAspectFit
            let xPostion = self.view.frame.width * CGFloat(i)
            imageView.frame = CGRect(x: xPostion, y: 0, width: self.mainScrollView.frame.width, height: self.mainScrollView.frame.height)
            
            mainScrollView.contentSize.width = mainScrollView.frame.width * CGFloat(i + 1)
            mainScrollView.addSubview(imageView)
        }
    }
    @IBAction func skipAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
       // self.performSegue(withIdentifier: "LoginToChat", sender: nil)
    }
}

extension InfoViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = Int(scrollView.contentSize.width) / imageArray.count
        pageControl.currentPage = Int(scrollView.contentOffset.x) / pageWidth
        
    }
}
