use std::net::SocketAddr;
use std::sync::Mutex;
use warp::Filter;

type Item = (String, String);
static ITEMS: std::sync::Mutex<Vec<Item>> = std::sync::Mutex::new(vec![]);

#[tokio::main]
async fn main() {
    let items = ITEMS.clone();

    // GET /items
    let get_items = warp::path!("items").and(warp::get()).map(move || {
        let items = items.lock().unwrap();
        warp::reply::json(&*items)
    });

    // POST /items
    let post_items = warp::path!("items").and(warp::post()).and(warp::body::json()).map(
        |new_item: Item| {
            let mut items = items.lock().unwrap();
            let id = format!("item-{}", items.len() + 1);
            items.push((id.clone(), new_item.1));
            warp::reply::json(&(id, new_item.1))
        },
    );

    // DELETE /items
    let delete_items = warp::path!("items").and(warp::delete()).map(|_| {
        let mut items = items.lock().unwrap();
        items.clear();
        warp::reply::json(&"removed")
    });

    // GET /health
    let health = warp::path!("health").and(warp::get()).map(|| warp::reply::json(&"healthy"));

    let routes = get_items
        .or(post_items)
        .or(delete_items)
        .or(health)
        .with(warp::log("rust-http-server"));

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    warp::serve(routes).run(addr).await;
}