# Open Questions

This page collects product decisions that remain undecided. Contributors should not treat them as confirmed implementation requirements.

## Columns

- May the summary be empty?
- Which state should a published work enter after an editor unpublishes it?
- Should an `Archived` state be added?
- Which transitions should be allowed between states?

The backend currently uses `UNPUBLISHED` after unpublishing and allows deletion
outside pending review. Reconcile this implementation with the intended rules
before changing it; see [Architecture](../architecture.md).

## Collections

- After a multi-author work is added to a collection, should co-authors other than the collection creator have management permissions?

## Search

- Which filters should search results provide?
- Which sort options should search results provide?

## Community Posts

- What should the exact community-post length limit be? It is tentatively around `500` words.

## Administration

- Which role should handle reports?
- Which levels and restrictions should a tiered penalty system include?
- Should the community-administrator role be enabled? If so, what are its responsibilities and permissions?

## Notifications

The backend already implements events, recipient deliveries, mentions, comment
replies, subscribed-author publication notifications and read state. The frontend
does not yet expose an inbox. See [the implemented flow](../architecture.md#notification-flow).
The product policy and additional triggers below remain undecided:

- Column approval, rejection, or unpublishing.
- Comments on columns or community posts.
- Replies to comments.
- Received likes or dislikes.
- New followers.
- Report outcomes.

## Translation

- Should the website provide built-in translation features?
