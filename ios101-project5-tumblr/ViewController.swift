// UPDATED ViewController.swift
//  ViewController.swift
//  ios101-project5-tumbler
//

import UIKit
import Nuke
import NukeExtensions

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    // Array to store the posts
    private var posts: [Post] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up table view
        setupTableView()
        
        // Set navigation title
        title = "Humans of New York"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Fetch posts
        fetchPosts()
    }
    
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 300
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshPosts() {
        fetchPosts()
    }

    func fetchPosts() {
        let url = URL(string: "https://api.tumblr.com/v2/blog/humansofnewyork/posts/photo?api_key=1zT8CiXGXFcQDyMFG7RtcfGLwTdDjFUJnZzKJaWTmgyK4lKGYk")!
        let session = URLSession.shared.dataTask(with: url) { data, response, error in
            
            // Stop refresh control on main thread
            DispatchQueue.main.async {
                self.tableView.refreshControl?.endRefreshing()
            }
            
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(statusCode) else {
                print("❌ Response error: \(String(describing: response))")
                return
            }

            guard let data = data else {
                print("❌ Data is NIL")
                return
            }

            do {
                let blog = try JSONDecoder().decode(Blog.self, from: data)

                DispatchQueue.main.async { [weak self] in
                    self?.posts = blog.response.posts
                    self?.tableView.reloadData()
                    
                    print("✅ We got \(blog.response.posts.count) posts!")
                    for post in blog.response.posts {
                        print("🍏 Summary: \(post.summary)")
                    }
                }

            } catch {
                print("❌ Error decoding JSON: \(error.localizedDescription)")
            }
        }
        session.resume()
    }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostTableViewCell
        
        let post = posts[indexPath.row]
        cell.configure(with: post)
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Handle cell selection if needed
    }
}

// MARK: - PostTableViewCell
class PostTableViewCell: UITableViewCell {
    
    @IBOutlet weak var postImageView: UIImageView!
    @IBOutlet weak var summaryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    private func configureUI() {
        // Configure image view
        postImageView.contentMode = .scaleAspectFill
        postImageView.clipsToBounds = true
        postImageView.layer.cornerRadius = 12
        
        // Add shadow to image view
        postImageView.layer.shadowColor = UIColor.black.cgColor
        postImageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        postImageView.layer.shadowOpacity = 0.1
        postImageView.layer.shadowRadius = 4
        
        // Configure summary label
        summaryLabel.numberOfLines = 0
        summaryLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        summaryLabel.textColor = .label
        summaryLabel.lineBreakMode = .byWordWrapping
        
        // Remove cell selection style
        selectionStyle = .none
        
        // Add cell background styling
        backgroundColor = .systemBackground
    }
    
    func configure(with post: Post) {
        // Set summary text
        summaryLabel.text = post.summary
        
        // Load image
        if let photo = post.photos.first {
            let url = photo.originalSize.url
            
            // Simple image loading with Nuke 12.8.0
            let request = ImageRequest(url: url)
            ImagePipeline.shared.loadImage(with: request) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self?.postImageView.image = response.image
                    case .failure(_):
                        self?.postImageView.image = UIImage(systemName: "photo")
                    }
                }
            }
        } else {
            // Set placeholder if no image
            postImageView.image = UIImage(systemName: "photo")
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        // Reset the image view
        postImageView.image = nil
        summaryLabel.text = nil
    }
}
