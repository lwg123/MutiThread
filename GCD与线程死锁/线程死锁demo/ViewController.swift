//
//  ViewController.swift
//  线程死锁demo
//
//  Created by weiguang on 2017/4/19.
//  Copyright © 2017年 weiguang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var inactiveQueue: DispatchQueue!
    var emptyArray: NSMutableArray! = NSMutableArray()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // test1会造成死锁，两种解决方法：1.async异步，2.新建了一个串行队列
        //test2()
        
        //NSMutableArray不是线程安全的，那么以下代码就会小概率崩溃
        /*
        let queue1 = DispatchQueue.init(label: "com.test.queue1")
        let queue2 = DispatchQueue.init(label: "com.test.queue2")
        queue1.async {
            for index in 1...500{
                self.emptyArray.add(index)
            }
        }
        
        queue2.async {
            for index in 500...1000{
                self.emptyArray.add(index)
            }
        }
         */
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //simpleQueues()
        //queuesWithQoS()
        //concurrentQueues()
        //queueWithDelay()
        fetchImage()
        //useWorkItem()
        
        if let queue = inactiveQueue {
            queue.activate()
        }
        
    }
    
}

// GCD使用例子
extension ViewController {
    
    
    
    func simpleQueues() {
        let queue = DispatchQueue(label: "com.changhong.myqueue")
        // 使用sync同步队列，必须红色打印完之后再打印蓝色，使用async异步队列，红色和蓝色同时执行
        queue.async {
            for i in 0..<10 {
                print("🔴",i)
            }
        }
        
        for i in 100..<110 {
            print("Ⓜ️",i)
        }
    }
    
    
    // Quality Of Service (QOS) 和优先级
    /*
     Qos代表不同的优先级
     
     userInteractive 最高
     userInitiated
     default
     utility
     background
     unspecified    最低优先级
     */
    // 不同的优先级打印顺序不同
    // 主队列默认拥有更高的优先级， queue1 与主列队是并行执行的。而 queue2 是最后完成的
    func queuesWithQoS() {
        let queue1 = DispatchQueue(label: "com.appcoda.queue2", qos: DispatchQoS.userInteractive)
        let queue2 = DispatchQueue(label: "com.appcoda.queue2", qos: DispatchQoS.background)
        
        queue1.async {
            for i in 0..<10 {
                print("🔴", i)
            }
        }
        
        queue2.async {
            for i in 100..<110 {
                print("🔵", i)
            }
        }
        // 主队列优先级最高
        for i in 1000..<1010 {
            print("Ⓜ️", i)
        }
        
    }
    
    // 并发队列
    
    func concurrentQueues() {
        // 这种是串行方式，一个执行完在执行下一个
        //let anotherQueue = DispatchQueue(label: "com.appcoda.anotherQueue", qos: .utility)
        
        // 这种是并发方式，可以同时执行多个任务
//       let anotherQueue = DispatchQueue(label: "com.appcoda.anotherQueue", qos: .utility, attributes: .concurrent)
        
         // 这个 attributes 参数也可以接受另一个名为 initiallyInactive 的值。如果使用这个值，任务不会被自动执行，而是需要开发者手动去触发
        /*
         在viewDidAppear(_:)里添加如下代码来执行
        if letqueue = inactiveQueue {
            queue.activate()
        }
         */
        //DispatchQueue 类的 activate() 方法会让任务开始执行。注意，这个队列并没有被指定为并发队列，因此它们会以串行的方式执行
//        let anotherQueue = DispatchQueue(label: "com.appcoda.anotherQueue", qos: .utility, attributes: .initiallyInactive)
        
        // 在指定 initiallyInactive 的同时将队列指定为并发队,两个值放入一个数组当中，作为 attributes 的参数
        let anotherQueue = DispatchQueue(label: "com.appcoda.anotherQueue", qos: .userInitiated, attributes: [.concurrent, .initiallyInactive])
        
        inactiveQueue = anotherQueue
        
        anotherQueue.async {
            for i in 0..<10 {
                print("🔴", i)
            }
        }
        
        
        anotherQueue.async {
            for i in 100..<110 {
                print("🔵", i)
            }
        }
        
        
        anotherQueue.async {
            for i in 1000..<1010 {
                print("⚫️", i)
            }
        }

    }
    
    
    
    //延迟执行
    func queueWithDelay() {
        let delayQueue = DispatchQueue(label: "com.appcoda.delayqueue", qos: .userInitiated)
        print(Date())
        let additionalTime: DispatchTimeInterval = .seconds(2)
        delayQueue.asyncAfter(deadline: .now() + additionalTime) {
            print(Date())
        }
//        delayQueue.asyncAfter(deadline: .now() + 0.75) {
//            print(Date())
//        }
    }
    
    
    // 通过主队列来更新 UI
    func fetchImage() {
        let imageURL: URL = URL(string: "http://www.appcoda.com/wp-content/uploads/2015/12/blog-logo-dark-400.png")!
        (URLSession(configuration: .default).dataTask(with: imageURL) { (imageDaata: Data?, response: URLResponse?, error: Error?) in
            if let data = imageDaata {
                print("Did download image data")
                //self.imageView.image = UIImage(data: data)
                // 在主线程更新UI
                DispatchQueue.main.async {
                    self.imageView.image = UIImage(data: data)
                }
            }
        }).resume()
    }
    
    // 使用 DispatchWorkItem 对象
    /*
     DispatchWorkItem 是一个代码块，它可以在任意一个队列上被调用，因此它里面的代码可以在后台运行，也可以在主线程运行
     */
    func useWorkItem() {
        var value = 10
        
        let workItem = DispatchWorkItem {
            value += 5
        }
        
//        workItem.perform()
        
        let queue = DispatchQueue.global(qos: .utility)
//        queue.async {
//            workItem.perform()
//        }
        // 这两种方法都可以执行
        queue.async(execute: workItem)
        
        workItem.notify(queue: DispatchQueue.main) { 
            print("Value = \(value)")
        }
    }
    
}



// 死锁解决方法
extension ViewController {
    
    // 线程死锁例子
    /*
     block中的11个数字没有被打印出来任何一个，viewDidLoad()中的End也没有被打印出来。也就是说，block没有得到执行的机会，viewDidLoad也没有继续执行下去。为什么block不执行呢？因为viewDidLoad也是执行在主队列的，它是正在被执行的任务，也就是说，viewDidLoad()是主队列的队头。主队列是串行队列，任务不能并发执行，同时只能有一个任务在执行，也就是队头的任务才能被出列执行。我们现在被执行的任务是viewDidLoad()，然后我们又将block入列到同一个队列，它比viewDidLoad()后入列，遵循先进先出的原理，它必须等到viewDidLoad()执行完，才能被执行。但是，dispatch_sync函数的特性是，等待block被执行完毕，才会返回，因此，只要block一天不被执行，它就一天不返回。我们知道，内部方法不返回，外部方法是不会执行下一行命令的。不等到sync函数返回，viewDidLoad打死也不会执行print End的语句，因此，viewDidLoad()一直没有执行完毕。block在等待着viewDidLoad(）执行完毕，它才能上，sync函数在等待着block执行完毕，它才能返回，viewDidLoad(）在等待着sync函数返回，它才能执行完毕。这样的三方循环等待关系，就造成了死锁。
     
     那么我们可以总结出GCD被阻塞（blocking）的原因有以下两点：
     GCD函数未返回，会阻塞正在执行的任务
     队列的执行室容量太小，在执行室有空位之前，会阻塞同一个队列中在等待的任务
     */
    func test1() {
        
        print("Start \(Thread.current)")
        
        // GCD同步函数
        DispatchQueue.main.sync {  //sync同步执行会死锁，改为async异步可以解决问题
            for i in 0...10{
                print("\(i) \(Thread.current)")
            }
        }
        
        print("End \(Thread.current)")
    }
    
    // 解决GCD死锁
    /*
     方法1：解决GCD函数未返回造成的阻塞
     dispatch_sync是同步函数，不具备开启新线程的能力，交给它的block，只会在当前线程执行，不论你传入的是串行队列还是并发队列，并且，它一定会等待block被执行完毕才返回。
     dispatch_async是异步函数，具备开启新线程的能力，但是不一定会开启新线程，交给它的block，可能在任何线程执行，开发者无法控制，是GCD底层在控制。它会立即返回，不会等待block被执行
     
     方法2：解决队列（Queue）阻塞
     解决队列阻塞，有两种方法：
     
     为队列的执行室扩容，让它可以并发执行多个任务，那么就不会因为A任务，造成B任务被阻塞了。
     把A和B任务放在两个不同的队列中，A就再也没有机会阻塞B了。因为每个队列都有自己的执行室。
     
     我们新建了一个串行队列，将block放入自己的串行队列，不再和viewDidLoad()处于一个队列，解决了队列阻塞，因此避免了死锁问题。
     */
        func test2() {
        print("Start \(Thread.current)")
        // 创建队列：concurrent是并发队列，不加该参数默认为串行队列；userInitiated代表优先级；这两个参数都可以不要，attributes：可以是一个数组[.concurrent, .initiallyInactive]
        let queue = DispatchQueue(label: "myBackgroundQueue", qos: .userInitiated, attributes:.concurrent)
        queue.sync {
            for i in 0...10{
                print("\(i) \(Thread.current)")
            }
        }
        print("End \(Thread.current)")
    }

}











