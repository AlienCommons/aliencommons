interface ApiResult<TData, TError> {
  data?: TData;
  error?: TError;
  response: Response;
}

function getErrorMessage(payload: unknown, response: Response): string {
  if (
    typeof payload === "object" &&
    payload !== null &&
    "message" in payload &&
    typeof payload.message === "string"
  ) {
    return payload.message;
  }
  return response.statusText || `API request failed with ${response.status}`;
}

export class ApiResponseError<TPayload = unknown> extends Error {
  readonly payload: TPayload;
  readonly status: number;

  constructor(response: Response, payload: TPayload) {
    super(getErrorMessage(payload, response));
    this.name = "ApiResponseError";
    this.payload = payload;
    this.status = response.status;
  }
}

export function unwrapApiResponse<TData, TError>(
  result: ApiResult<TData, TError>
): TData {
  if (result.data !== undefined) {
    return result.data;
  }
  throw new ApiResponseError(result.response, result.error);
}
