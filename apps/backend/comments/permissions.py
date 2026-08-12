from rest_framework import permissions


class CommentPermission(permissions.BasePermission):
    """
    Anyone can read comments; authenticated users can create them.
    Authors can edit and soft-delete their own comments.
    """

    def has_permission(self, request, view):
        return (
            request.method in permissions.SAFE_METHODS
            or request.user.is_authenticated
        )

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return obj.author_id == request.user.id
